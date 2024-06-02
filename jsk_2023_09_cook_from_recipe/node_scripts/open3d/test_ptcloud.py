import rospy
from sensor_msgs.msg import PointCloud2, PointField, Image, CameraInfo
from cv_bridge import CvBridge
import numpy as np
import open3d as o3d
import struct
import message_filters

class RGBDPointCloudPublisher:
    def __init__(self):
        rospy.init_node('rgbd_point_cloud_publisher', anonymous=True)
        self.bridge = CvBridge()

        self.rgb_sub = message_filters.Subscriber('/kinect_head_remote/rgb/image_rect_color', Image)
        self.depth_sub = message_filters.Subscriber('/kinect_head_remote/depth_registered/image_rect', Image)

        self.ts = message_filters.ApproximateTimeSynchronizer([self.rgb_sub, self.depth_sub], 10, 0.1)
        self.ts.registerCallback(self.rgbd_callback)

        self.camera_info_sub = rospy.Subscriber('/kinect_head/depth_registered/camera_info', CameraInfo, self.camera_info_callback)
        self.intrinsic = o3d.camera.PinholeCameraIntrinsic()
        self.intrinsic_set = False

        self.point_cloud_publisher = rospy.Publisher('/colored_point_cloud', PointCloud2, queue_size=10)

    def rgbd_callback(self, rgb_msg, depth_msg):
        if not self.intrinsic_set:
            rospy.logwarn("Waiting for camera intrinsic parameters...")
            return

        rgb_image = self.bridge.imgmsg_to_cv2(rgb_msg, "bgr8")
        depth_image = self.bridge.imgmsg_to_cv2(depth_msg, "32FC1")

        rgbd_image = o3d.geometry.RGBDImage.create_from_color_and_depth(
            o3d.geometry.Image(rgb_image),
            o3d.geometry.Image(depth_image),
            convert_rgb_to_intensity=False
        )

        # pinhole_camera_intrinsic = o3d.camera.PinholeCameraIntrinsic(
        #     o3d.camera.PinholeCameraIntrinsicParameters.PrimeSenseDefault
        # )

        point_cloud = o3d.geometry.PointCloud.create_from_rgbd_image(
            rgbd_image,
            self.intrinsic
        )

        self.publish_point_cloud(point_cloud, rgb_msg.header)

    def camera_info_callback(self, camera_info_msg):
        if not self.intrinsic_set:
            self.intrinsic.set_intrinsics(
                camera_info_msg.width, camera_info_msg.height,
                camera_info_msg.K[0], camera_info_msg.K[4],
                camera_info_msg.K[2], camera_info_msg.K[5])
            self.intrinsic_set = True

    def publish_point_cloud(self, point_cloud, header):
        ros_point_cloud = self.convert_to_ros_point_cloud(point_cloud, header)
        self.point_cloud_publisher.publish(ros_point_cloud)

    def convert_to_ros_point_cloud(self, point_cloud, header):
        points = np.asarray(point_cloud.points)
        colors = np.asarray(point_cloud.colors)

        ros_msg = PointCloud2()
        ros_msg.header = header

        import ipdb
        ipdb.set_trace()

        ros_msg.height = 1
        ros_msg.width = points.shape[0]

        ros_msg.fields = [
            PointField('x', 0, PointField.FLOAT32, 1),
            PointField('y', 4, PointField.FLOAT32, 1),
            PointField('z', 8, PointField.FLOAT32, 1),
            PointField('rgb', 12, PointField.UINT32, 1)
        ]
        ros_msg.is_bigendian = False
        ros_msg.point_step = 16
        ros_msg.row_step = ros_msg.point_step * points.shape[0]
        ros_msg.is_dense = True

        data = []
        for i in range(points.shape[0]):
            x, y, z = points[i]
            r, g, b = colors[i]
            rgb = struct.unpack('I', struct.pack('BBBB', int(b * 255), int(g * 255), int(r * 255), 255))[0]
            data.append(struct.pack('fffI', x, y, z, rgb))

        ros_msg.data = b''.join(data)
        return ros_msg

if __name__ == "__main__":
    RGBDPointCloudPublisher()
    rospy.spin()
