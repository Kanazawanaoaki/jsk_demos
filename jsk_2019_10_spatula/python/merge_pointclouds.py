#!/usr/bin/env python
import rospy
from sensor_msgs.msg import PointCloud2
import sensor_msgs.point_cloud2 as pc2
import numpy as np
import ctypes
import struct
from sensor_msgs.msg import PointCloud2, PointField
from std_msgs.msg import Header
import sys

import math


def main():
    #pub = rospy.Publisher('feedback_touching', Float64, queue_size=10)
    Merger = MergePointClouds()
    rospy.init_node('merge_pointcloud', anonymous=True)
    rospy.Subscriber("/pcl_nodelet/hsi_filter_brown/output", PointCloud2, Merger.callback_brown)
    rospy.Subscriber("/pcl_nodelet/hsi_filter_white/output", PointCloud2, Merger.callback_white)
    rospy.spin()

class MergePointClouds:
    def __init__(self):
        self.pub = rospy.Publisher("point_cloud2", PointCloud2, queue_size=2)
        self.n_brown = 0
        self.n_white = 0

    def callback_white(self,ptcloud):
        self.ptcloud_white = ptcloud
        self.n_white = self.n_white + 1
        print "new white pointcloud available n_brown:%d  n_white:%d" % (self.n_brown,self.n_white)
        self.points_white = self.read_pointcloud(ptcloud)
        if self.n_brown == self.n_white:
            print "publish in white"
            ptcloud_merged = self.generate_pointcloud()
            self.pub.publish(ptcloud_merged)

    def callback_brown(self,ptcloud):
        self.ptcloud_brown = ptcloud
        self.n_brown = self.n_brown + 1
        self.points_brown = self.read_pointcloud(ptcloud)
        print "new brown pointcloud available n_brown:%d  n_white:%d" % (self.n_brown,self.n_white)
        if self.n_brown == self.n_white:
            print "publish in brown"
            ptcloud_merged = self.generate_pointcloud()
            self.pub.publish(ptcloud_merged)


    def read_pointcloud(self,ptcloud):
        fields = ptcloud.fields
        fields[3].datatype = 6
        points = pc2.read_points_list(ptcloud, skip_nans=True)
        return points

    def generate_pointcloud(self):
        header =  self.ptcloud_brown.header
        fields = self.ptcloud_brown.fields
        points = self.points_brown + self.points_white
        ptcloud_merged = pc2.create_cloud(header, fields, points)
        ptcloud_merged.fields[3].datatype = 7
        return ptcloud_merged


if __name__ == "__main__":
    main()