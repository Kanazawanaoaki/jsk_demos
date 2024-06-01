#!/usr/bin/env python

import rospy
import open3d as o3d
import sensor_msgs.point_cloud2 as pc2
from sensor_msgs.msg import PointCloud2, PointField
from std_srvs.srv import Empty, EmptyResponse
import threading
import time
import numpy as np
from std_msgs.msg import Header

class PointCloudMerger:
    def __init__(self):
        rospy.init_node('pointcloud_merger')

        self.pointcloud_sub = rospy.Subscriber('/kinect_head/depth_registered/points', PointCloud2, self.pointcloud_callback)
        self.merged_pub = rospy.Publisher('/merged_pointcloud', PointCloud2, queue_size=1)

        self.lock = threading.Lock()
        self.pointclouds = []
        self.merged_cloud = None

        self.service = rospy.Service('/start_merging', Empty, self.service_callback)
        self.merging = False
        self.store_sec = 1 #10

    def pointcloud_callback(self, msg):
        if self.merging:
            with self.lock:
                self.pointclouds.append(msg)
        if not (self.merged_cloud is None) and not self.merging:
            self.merged_pub.publish(self.merged_cloud)

    def service_callback(self, req):
        rospy.loginfo("Service called, starting to merge point clouds for {} seconds.".format(self.store_sec))
        self.merging = True
        self.merged_cloud = None

        rospy.Timer(rospy.Duration(self.store_sec), self.stop_merging, oneshot=True)

        return EmptyResponse()

    def stop_merging(self, event):
        self.merging = False
        with self.lock:
            if self.pointclouds:
                self.merged_cloud = self.merge_pointclouds(self.pointclouds)
                self.merged_pub.publish(self.merged_cloud)
                self.pointclouds = []

        rospy.loginfo("Finished merging point clouds and published the result.")

    def merge_pointclouds(self, clouds):
        all_points = []

        for cloud in clouds:
            points = list(pc2.read_points(cloud, field_names=("x", "y", "z"), skip_nans=True))
            all_points.extend(points)

        np_points = np.array(all_points)

        open3d_cloud = o3d.geometry.PointCloud()
        open3d_cloud.points = o3d.utility.Vector3dVector(np_points[:, :3])

        merged_points = np.asarray(open3d_cloud.points)

        merged_header = clouds[0].header
        merged_cloud = pc2.create_cloud_xyz32(merged_header, merged_points)

        return merged_cloud

    # def merge_pointclouds(self, clouds):
    #     all_points = []

    #     for cloud in clouds:
    #         points = list(pc2.read_points(cloud, field_names=("x", "y", "z", "rgb"), skip_nans=True))
    #         all_points.extend(points)

    #     np_points = np.array(all_points)

    #     open3d_cloud = o3d.geometry.PointCloud()
    #     open3d_cloud.points = o3d.utility.Vector3dVector(np_points[:, :3])

    #     # Extract color information
    #     colors = np_points[:, 3].astype(np.uint32)  # Convert to uint32
    #     r = (colors >> 16) & 0xFF
    #     g = (colors >> 8) & 0xFF
    #     b = colors & 0xFF
    #     colors = np.stack((r, g, b), axis=-1)
    #     colors = colors.astype(np.uint8)  # Convert to uint8
    #     open3d_cloud.colors = o3d.utility.Vector3dVector(colors / 255.0)  # Normalize to [0, 1]

    #     merged_points = np.hstack((np.asarray(open3d_cloud.points), np.asarray(open3d_cloud.colors)))

    #     merged_header = clouds[0].header
    #     merged_cloud = self.create_colored_pointcloud2(merged_header, merged_points)

    #     return merged_cloud

    # def create_colored_pointcloud2(self, header, points):
    #     fields = [
    #         PointField('x', 0, PointField.FLOAT32, 1),
    #         PointField('y', 4, PointField.FLOAT32, 1),
    #         PointField('z', 8, PointField.FLOAT32, 1),
    #         PointField('r', 12, PointField.UINT8, 1),  # Changed to UINT8
    #         PointField('g', 13, PointField.UINT8, 1),  # Changed to UINT8
    #         PointField('b', 14, PointField.UINT8, 1),  # Changed to UINT8
    #     ]

    #     cloud_data = []
    #     for p in points:
    #         x, y, z = p[:3]
    #         r, g, b = p[3:]
    #         cloud_data.append([x, y, z, r, g, b])

    #     return pc2.create_cloud(header, fields, cloud_data)

    def run(self):
        rospy.spin()

if __name__ == '__main__':
    merger = PointCloudMerger()
    merger.run()
