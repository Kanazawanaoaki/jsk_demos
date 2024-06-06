#!/usr/bin/env python
import rospy
from sensor_msgs.msg import PointCloud2
import sensor_msgs.point_cloud2 as pc2
import numpy as np
import ctypes
import struct
from collections import deque
from sensor_msgs.msg import PointCloud2, PointField
from std_msgs.msg import Header
import sys

import math


def main():
    Merger = MergePointClouds()
    rospy.init_node('merge_pointcloud', anonymous=True)
    rospy.Subscriber("/kinect_head_remote/depth_registered/points", PointCloud2, Merger.ptcloud_callback)
    rospy.spin()

class MergePointClouds:
    def __init__(self):
        self.pub = rospy.Publisher("/merged_point_cloud", PointCloud2, queue_size=2)
        self.num_ptcloud = 5

        self.ptcloud_count = 0
        self.latest_ptclouds = deque(maxlen=self.num_ptcloud)
        self.current_point = None

    def ptcloud_callback(self, ptcloud):
        self.current_point = ptcloud
        self.ptcloud_count = self.ptcloud_count + 1
        print("new pointcloud available ptcloud_count:%d " % (self.ptcloud_count))
        self.latest_ptclouds.append(self.read_pointcloud(ptcloud))
        print(len(self.latest_ptclouds))
        if len(self.latest_ptclouds) >= self.num_ptcloud:
            print("publish in ptcloud")
            ptcloud_merged = self.generate_pointcloud()
            self.pub.publish(ptcloud_merged)

    def read_pointcloud(self, ptcloud):
        fields = ptcloud.fields
        fields[3].datatype = 6
        points = pc2.read_points_list(ptcloud, skip_nans=True)
        return points

    def generate_pointcloud(self):
        header =  self.current_point.header
        fields = self.current_point.fields
        points = None
        for ptcloud in self.latest_ptclouds:
            if points is None:
                points = ptcloud
            else:
                points = points + ptcloud
        ptcloud_merged = pc2.create_cloud(header, fields, points)
        ptcloud_merged.fields[3].datatype = 7
        return ptcloud_merged


if __name__ == "__main__":
    main()
