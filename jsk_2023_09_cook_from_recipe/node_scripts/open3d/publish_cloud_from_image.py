import open3d as o3d
import rospy
from sensor_msgs.msg import PointCloud2, PointField
from sensor_msgs.msg import Image
from std_srvs.srv import Trigger, TriggerResponse
import numpy as np
import message_filters
from cv_bridge import CvBridge
import struct

class RGBDPointCloudPublisher:
    def __init__(self):
        self.bridge = CvBridge()
        self.point_cloud_publisher = rospy.Publisher('/point_cloud_from_images', PointCloud2, queue_size=10)

        self.rgb_sub = message_filters.Subscriber('/kinect_head_remote/rgb/image_rect_color', Image)
        self.depth_sub = message_filters.Subscriber('/kinect_head_remote/depth_registered/image_rect', Image)
        self.ts = message_filters.ApproximateTimeSynchronizer([self.rgb_sub, self.depth_sub], 10, 0.1)
        self.ts.registerCallback(self.rgbd_callback)

    def rgbd_callback(self, rgb_msg, depth_msg):
        self.latest_header = rgb_msg.header  # Save the latest header from the RGB image
        rgb_image = self.bridge.imgmsg_to_cv2(rgb_msg, "bgr8")
        depth_image = self.bridge.imgmsg_to_cv2(depth_msg, "32FC1")
        self.create_colored_point_cloud(rgb_image, depth_image)

    def create_colored_point_cloud(self, rgb_image, depth_image):
        rgbd_image = o3d.geometry.RGBDImage.create_from_color_and_depth(
            o3d.geometry.Image(rgb_image),
            o3d.geometry.Image(depth_image),
            convert_rgb_to_intensity=False
        )
        pinhole_camera_intrinsic = o3d.camera.PinholeCameraIntrinsic(
            o3d.camera.PinholeCameraIntrinsicParameters.PrimeSenseDefault
        )
        point_cloud = o3d.geometry.PointCloud.create_from_rgbd_image(
            rgbd_image,
            pinhole_camera_intrinsic
        )

        self.publish_point_cloud(point_cloud)

    def publish_point_cloud(self, point_cloud):
        ros_point_cloud = self.convert_to_ros_point_cloud(point_cloud)
        while not rospy.is_shutdown():
            self.point_cloud_publisher.publish(ros_point_cloud)
            rospy.sleep(0.1)  # Adjust the publishing rate as needed
            # rospy.loginfo("publish point cloud")

    # def convert_to_ros_point_cloud(self, point_cloud):
    #     # Conversion code (Open3D PointCloud to ROS PointCloud2) goes here
    #     # Implement conversion logic to convert Open3D PointCloud to ROS PointCloud2
    #     # Placeholder:
    #     return PointCloud2()
    def convert_to_ros_point_cloud(self, point_cloud):
        point_cloud.transform([[1, 0, 0, 0],
                               [0, -1, 0, 0],
                               [0, 0, -1, 0],
                               [0, 0, 0, 1]])

        points = np.asarray(point_cloud.points)
        colors = np.asarray(point_cloud.colors)

        ros_msg = PointCloud2()
        if self.latest_header is not None:
            ros_msg.header = self.latest_header
        else:
            ros_msg.header.stamp = rospy.Time.now()
            ros_msg.header.frame_id = "camera_link"

        # import ipdb
        # ipdb.set_trace()
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
    rospy.init_node('rgbd_point_cloud_publisher')
    RGBDPointCloudPublisher()
    rospy.spin()
