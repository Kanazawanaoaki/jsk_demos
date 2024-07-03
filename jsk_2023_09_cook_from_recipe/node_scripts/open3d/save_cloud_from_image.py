import open3d as o3d
import rospy
from sensor_msgs.msg import PointCloud2, PointField
from sensor_msgs.msg import Image
from std_srvs.srv import Trigger, TriggerResponse
import numpy as np
import message_filters
from cv_bridge import CvBridge
import cv2

class RGBDPointCloudPublisher:
    def __init__(self):
        self.bridge = CvBridge()
        self.point_cloud_publisher = rospy.Publisher('/point_cloud_from_images', PointCloud2, queue_size=10)
        self.service = rospy.Service('/save_rgbd_data', Trigger, self.service_callback)

        self.rgb_sub = message_filters.Subscriber('/kinect_head_remote/rgb/image_rect_color', Image)
        self.depth_sub = message_filters.Subscriber('/kinect_head_remote/depth_registered/image_rect', Image)
        self.ts = message_filters.ApproximateTimeSynchronizer([self.rgb_sub, self.depth_sub], 10, 0.1)
        self.ts.registerCallback(self.rgbd_callback)

        self.rgb_image = None
        self.depth_image = None

    def rgbd_callback(self, rgb_msg, depth_msg):
        self.latest_header = rgb_msg.header  # Save the latest header from the RGB image
        self.rgb_image = self.bridge.imgmsg_to_cv2(rgb_msg, "bgr8")
        self.depth_image = self.bridge.imgmsg_to_cv2(depth_msg, "32FC1")

    def service_callback(self, request):
        rospy.loginfo("Service call received, starting data collection...")
        if self.rgb_image is None or self.depth_image is None:
            return TriggerResponse(success=False, message="RGB or Depth image is not comming yet.")
        else:
            self.create_colored_point_cloud(self.rgb_image, self.depth_image)
            return TriggerResponse(success=True, message="Point cloud created and saved.")

    def create_colored_point_cloud(self, bgr_image, depth_image):
        rgb_image = cv2.cvtColor(bgr_image, cv2.COLOR_BGR2RGB)

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

        self.save_point_cloud(point_cloud)

    def save_point_cloud(self, point_cloud):
        point_cloud.transform([[1, 0, 0, 0],
                               [0, -1, 0, 0],
                               [0, 0, -1, 0],
                               [0, 0, 0, 1]])
        # import ipdb
        # ipdb.set_trace()
        # Step 5: Visualize the point cloud
        o3d.visualization.draw_geometries([point_cloud])

        # Step 6: Save the point cloud (optional)
        # o3d.io.write_point_cloud("output_point_cloud.ply", point_cloud)
        o3d.io.write_point_cloud("output_point_cloud.pcd", point_cloud)
        rospy.loginfo("PointCloud is saved.")

if __name__ == "__main__":
    rospy.init_node('rgbd_point_cloud_publisher')
    RGBDPointCloudPublisher()
    rospy.spin()
