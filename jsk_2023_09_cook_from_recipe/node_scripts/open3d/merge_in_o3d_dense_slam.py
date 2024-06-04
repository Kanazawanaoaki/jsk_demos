#!/usr/bin/env python
import rospy
import message_filters
from sensor_msgs.msg import Image, CameraInfo
from std_srvs.srv import Trigger, TriggerResponse
from cv_bridge import CvBridge
import numpy as np
import open3d as o3d
import open3d.core as o3c
from sensor_msgs.msg import PointCloud2
import sensor_msgs.point_cloud2 as pc2

class Open3DSlamNode:
    def __init__(self):
        # Initialization of ROS node and CvBridge
        self.bridge = CvBridge()

        # Camera internal parameter settings (modified to match the camera being used)
        self.intrinsic = o3d.camera.PinholeCameraIntrinsic()
        self.intrinsic_set = False

        # ROS subscriber settings for depth and color images
        self.depth_sub = message_filters.Subscriber('/kinect_head/depth_registered/image_raw', Image)
        self.color_sub = message_filters.Subscriber('/kinect_head/rgb/image_color', Image)

        # self.depth_sub = message_filters.Subscriber('/kinect_head/depth_registered/image_rect', Image)
        # self.color_sub = message_filters.Subscriber('/kinect_head/rgb/image_rect_color', Image)
        # self.depth_sub = message_filters.Subscriber('/kinect_head/depth_registered/image', Image)
        # self.color_sub = message_filters.Subscriber('/kinect_head/rgb/image_rect_color', Image)
        # self.depth_sub = message_filters.Subscriber('/kinect_head_remote/depth_registered/image_rect', Image)
        # self.color_sub = message_filters.Subscriber('/kinect_head_remote/rgb/image_rect_color', Image)

        ## Setting up the ROS service
        self.service = rospy.Service('/start_o3d_dense_slam', Trigger, self.start_service_callback)
        self.service = rospy.Service('/stop_o3d_dense_slam', Trigger, self.stop_service_callback)
        self.collecting = False
        self.publishing = False

        self.camera_info_sub = rospy.Subscriber('/kinect_head/depth_registered/camera_info', CameraInfo, self.camera_info_callback)
        self.pc_pub = rospy.Publisher("/open3d_dense_slam_cloud", PointCloud2, queue_size=10)

        # Synchronizing depth and color images with synchronized message filters
        self.ts = message_filters.ApproximateTimeSynchronizer(
            [self.depth_sub, self.color_sub], 10, 1)
        self.ts.registerCallback(self.callback)

        # SLAM-specific settings
        self.device = o3c.Device("CUDA:0")  # or “CPU:0
        self.voxel_size = 0.005  # voxel size
        self.depth_scale = 1000.0  # Depth Scale
        self.depth_max = 1.5  # Maximum depth
        self.depth_min = 0.01
        self.odometry_distance_thr = 0.07
        self.trunc_voxel_multiplier = 4.0

        self.input_frame = None
        self.raycast_frame = None
        self.frame_num = 0

        self.creat_points = None

        self.frame_id = None

        # Initialize the SLAM model
        self.T_frame_to_model = o3c.Tensor(np.identity(4))
        self.model = o3d.t.pipelines.slam.Model(self.voxel_size,
                                                4,
                                                10000,
                                                self.T_frame_to_model,
                                                self.device)

    def camera_info_callback(self, camera_info_msg):
        # Extracting and setting internal parameters from ROS camera info messages
        if not self.intrinsic_set:
            self.intrinsic.set_intrinsics(
                camera_info_msg.width, camera_info_msg.height,
                camera_info_msg.K[0], camera_info_msg.K[4],
                camera_info_msg.K[2], camera_info_msg.K[5])
            # self.handle_camera_info(camera_info_msg)
            self.intrinsic_set = True

    def start_service_callback(self, request):
        rospy.loginfo("Service call received, starting data collection...")
        self.collecting = True

        ## Initialize
        self.input_frame = None
        self.raycast_frame = None
        self.frame_num = 0

        self.creat_points = None

        return TriggerResponse(success=True, message="Start to collect data and do dense slam.")

    def stop_service_callback(self, request):
        rospy.loginfo("Service call received, starting cloud publish...")
        self.collecting = False
        self.publishing = True

        return TriggerResponse(success=True, message="Start to publish dense slam cloud.")

    def callback(self, depth_msg, color_msg):
        if not self.intrinsic_set:
            rospy.logwarn("Waiting for camera intrinsic parameters...")
            return
        elif not self.collecting and not self.publishing:
            rospy.logwarn("Waiting for start service call...")
            return
        elif not self.collecting and self.publishing:
            if self.creat_points is None:
                rospy.logwarn("Point is not created...")
            else:
                rospy.logwarn("Publish pointcloud...")
                self.publish_pointcloud()
            return

        try:
            self.frame_id = depth_msg.header.frame_id
            # Convert ROS images to OpenCV format
            depth_image = self.bridge.imgmsg_to_cv2(
                depth_msg, desired_encoding='16UC1')
            # depth_image = self.bridge.imgmsg_to_cv2(
            #     depth_msg, desired_encoding='32FC1')

            color_image = self.bridge.imgmsg_to_cv2(color_msg, "rgb8")
            # color_image = self.bridge.imgmsg_to_cv2(color_msg, "bgr8")

            # depth_image = depth_image.astype(np.float32)
            # color_image = color_image.astype(np.float32)

            if depth_image is None or color_image is None:
                rospy.logerr("Received an empty image.")
                return

            # Convert OpenCV images to Open3D format
            depth_o3d = o3d.t.geometry.Image(depth_image)
            color_o3d = o3d.t.geometry.Image(color_image)

            rgbd_image = o3d.t.geometry.RGBDImage(
                    color_o3d, depth_o3d).cuda()
            # SLAM processing
            self.perform_slam(rgbd_image)

            # rospy.logwarn("Publish pointcloud...")
            # self.publish_pointcloud()
        except Exception as e:
            rospy.logerr("Error processing Open3D SLAM: %s", e)
            pass

    def perform_slam(self, rgbd_image):
        # Convert an Open3D image to a tensor
        # depth_image = np.asarray(rgbd_image.depth)
        # color_image = np.asarray(rgbd_image.color)

        # depth_tensor = o3c.Tensor(depth_image, o3c.Dtype.UInt16).to(self.device)
        # color_tensor = o3c.Tensor(color_image, o3c.Dtype.UInt8).to(self.device)

        # print(np.asarray(rgbd_image.depth.to_legacy()))
        # print(rgbd_image.color)

        # Initializing Input Frames
        if self.input_frame is None:
            self.input_frame = o3d.t.pipelines.slam.Frame(rgbd_image.depth.rows, rgbd_image.depth.columns,
                                                          o3c.Tensor(self.intrinsic.intrinsic_matrix), self.device)

        if self.raycast_frame is None:
            self.raycast_frame = o3d.t.pipelines.slam.Frame(rgbd_image.depth.rows, rgbd_image.depth.columns,
                                                            o3c.Tensor(self.intrinsic.intrinsic_matrix), self.device)

        self.input_frame.set_data_from_image('depth', rgbd_image.depth)
        self.input_frame.set_data_from_image('color', rgbd_image.color)

        # Tracking and updating models
        if self.frame_num > 0:
            result = self.model.track_frame_to_model(self.input_frame,
                                                     self.raycast_frame,
                                                     self.depth_scale,
                                                     self.depth_max,
                                                     self.odometry_distance_thr)
            self.T_frame_to_model = self.T_frame_to_model @ result.transformation

        # Updating models
        self.model.update_frame_pose(self.frame_num, self.T_frame_to_model)
        self.model.integrate(self.input_frame, self.depth_scale,
                             self.depth_max, self.trunc_voxel_multiplier)
        self.model.synthesize_model_frame(self.raycast_frame, self.depth_scale,
                                          self.depth_min, self.depth_max,
                                          self.trunc_voxel_multiplier, False)
        self.frame_num += 1

        # Extracting a point cloud from a model
        pcd = self.model.extract_pointcloud().to_legacy()

        # Convert Open3D point clouds to ROS messages
        points = np.asarray(pcd.points)
        colors = np.asarray(pcd.colors)
        if len(points) == 0:
            return
        r, g, b = (colors * 255).astype(np.uint8).T

        rgba = np.left_shift(np.ones_like(r, dtype=np.uint32) * 255, 24) | \
            np.left_shift(r.astype(np.uint32), 16) | \
            np.left_shift(g.astype(np.uint32), 8) | \
            b.astype(np.uint32)

        self.creat_points = np.concatenate((points, rgba[:, np.newaxis].astype(np.uint32)), axis=1, dtype=object)

    def publish_pointcloud(self):
        # Defining the PointField Structure
        fields = [pc2.PointField('x', 0, pc2.PointField.FLOAT32, 1),
                  pc2.PointField('y', 4, pc2.PointField.FLOAT32, 1),
                  pc2.PointField('z', 8, pc2.PointField.FLOAT32, 1),
                  pc2.PointField('rgba', 12, pc2.PointField.UINT32, 1)]

        header = rospy.Header()
        header.stamp = rospy.Time.now()
        # header.frame_id = "base_link" # Set to the appropriate frame ID
        header.frame_id = self.frame_id # Set to the appropriate frame ID

        # Create a PointCloud2
        cloud_data = pc2.create_cloud(header, fields, self.creat_points)

        # Publish a point cloud
        self.pc_pub.publish(cloud_data)


def main():
    rospy.init_node('open3d_slam_node')
    slam_node = Open3DSlamNode()
    rospy.spin()

if __name__ == '__main__':
    main()
