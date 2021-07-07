#!/usr/bin/env python
import rospy
import sensor_msgs.point_cloud2 as pc2
import numpy as np
import ctypes
import struct
from sensor_msgs.msg import PointCloud2, PointField, JointState
from std_msgs.msg import Header, String
import sys
import math
import tf
import time
import message_filters
#if debug is set True, the ptclouds that are merged are also publihsed seperately
debug = True

print "start!"

def main():
    rospy.init_node('merge_pointcloud_sequence',anonymous=True)
    Merger = MergePointClouds()

    # ptcloud_sub = message_filters.Subscriber('/pcl_nodelet/ExtractIndices/output', PointCloud2)
    # semantic_sub = message_filters.Subscriber("/semantic_annotation_merge",Header)
    # ts = message_filters.ApproximateTimeSynchronizer([ptcloud_sub, semantic_sub],10,0.1,allow_headerless=True)
    # ts.registerCallback(Merger.callback_all)

    ptcloud_sub = message_filters.Subscriber('/pcl_nodelet/ExtractIndices/output', PointCloud2, queue_size=1, buff_size=2**24)
    semantic_sub = message_filters.Subscriber("/semantic_annotation_merge",Header ,queue_size=1,buff_size=2**24)
    ts = message_filters.ApproximateTimeSynchronizer([ptcloud_sub, semantic_sub],queue_size=100,slop=1,allow_headerless=True)
    ts.registerCallback(Merger.callback_all)

    rospy.spin()

class MergePointClouds:
    def __init__(self):
        self.pub = rospy.Publisher("point_cloud_sequence_merged", PointCloud2, queue_size=2)
        if debug:
            self.pub_debug = rospy.Publisher("point_cloud_one_look", PointCloud2, queue_size=2)
        self.listener = tf.TransformListener()
        self.add_ptcloud = False #if set to True, the next published ptcloud is added
        self.points = []

    def callback_all(self , ptcloud, semantic):
        rospy.loginfo(semantic.stamp)
        print "callback"
        rospy.loginfo(ptcloud.header.stamp)
        self.callback_semantics(semantic)
        self.callback_ptcloud(ptcloud)

    def callback_semantics(self,msg):
        """
        input           msg: string that describes what the robot is doing
        output          none
        description     - publishes ptcloud and starts a new points array, if semantic annotation determines the end of vision
                        - sets flag to add the next published ptcloud, if semantic annotation dtermines a new vision position is reached
        """
        print "semantics callback"
        split_action = msg.frame_id.split("_")
        if split_action[0] == "vision":
            if split_action[1] == "end":
                print "publishing pointcloud"
                ptcloud_merged = self.generate_pointcloud()
                self.pub.publish(ptcloud_merged)
                self.points = []
            else:
                self.add_ptcloud = True


    def callback_ptcloud(self,ptcloud):
        """
        input           ptcloud:    sensor_msgs.msg PointCloud2
        output          none
        description     - if flag self.add_ptcloud is set, it calls the functions to read and transform the ptcloud and add it to self.points
                        - if the debug flag is set it also publishes the transformed ptcloud
        """
        print "ptcloud callback"
        self.ptcloud = ptcloud #always have the newest version of the ptcoud
        if self.add_ptcloud:
            #look up trafo right away as otherwise there is a delay due to read_ptcloud
            self.add_ptcloud = False
            now = ptcloud.header.stamp
            self.trafo = self.get_transform(now)
            points = self.read_pointcloud(ptcloud)
            points_transformed = self.transform_points(points)
            self.points = self.points + points_transformed
            #publish the ptcloud of one look for debugging
            if debug:
                ptcloud_merged = self.generate_pointcloud(points_transformed)
                self.pub_debug.publish(ptcloud_merged)



    def transform_points(self,points):
        """
        input           points:     List of namedtuples containing the values for each point from the ptcloud
        output          point_list: List conatinnig the values of each point, transformed into '/l_gripper_tool_frame' KS
        description     transforms the points from '/head_mount_kinect_rgb_optical_frame' into /l_gripper_tool_frame KS
        """
        xyz = []
        rgb = []
        for point in points:
            xyz.append([point.x,point.y,point.z])
            rgb.append(point.rgb)
        xyz = np.array(xyz)
        rgb = np.array(rgb)
        rgb = np.reshape(rgb,[len(rgb),1])

        #trafo = self.get_transform()
        trafo = self.trafo
        xyz1 = np.hstack([xyz,np.ones([np.shape(xyz)[0],1])])
        xyz1_transformed = np.transpose(np.matmul(trafo,np.transpose(xyz1)))

        xyz_transformed = xyz1_transformed[:,0:3]
        point_array = np.hstack([xyz_transformed,rgb])
        point_list = list(point_array)
        return point_list

    def quat2mat(self,quat):
        """
        input           quat 4-element list/array representing a quaternion in the order x,y,z,w
        output          mat, 3x3 array representing a rotation matrix
        description     converts quaternion to rotation matrix
        resources       - http://docs.ros.org/melodic/api/geometry_msgs/html/msg/Quaternion.html
                        - implementation from https://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToMatrix/index.htm
        """
        x = quat[0]
        y = quat[1]
        z = quat[2]
        w = quat[3]
        mat = np.array([[1-(2*(y**2))-(2*(z**2)), 2*x*y-(2*z*w), 2*x*z+(2*y*w)],
                        [2*x*y + 2*z*w, 1-(2*(x**2))-(2*(z**2)), 2*y*z-(2*x*w)],
                        [2*x*z-(2*y*w), 2*y*z + 2*x*w, 1-(2*(x**2))-(2*(y**2))]])
        return mat

    def get_transform(self,now):
        """
        input           none
        output          trafo:  transformation matrix that transforms from '/head_mount_kinect_rgb_optical_frame' to '/l_gripper_tool_frame'
        """
        self.listener.waitForTransform('/l_gripper_tool_frame','/head_mount_kinect_rgb_optical_frame',now,rospy.Duration(4.0))
        (trans,rot) = self.listener.lookupTransform('/l_gripper_tool_frame','/head_mount_kinect_rgb_optical_frame',now)
        # (trans,rot) = self.listener.lookupTransform('/l_gripper_tool_frame', '/head_mount_kinect_rgb_optical_frame', rospy.Time(0))
        rotmat = self.quat2mat(rot)
        trans_v = np.array(trans)
        trans_v = np.reshape(trans,[3,1])
        trafo = np.vstack([np.hstack([rotmat,trans_v]),np.array([0,0,0,1])])
        return trafo

    def read_pointcloud(self,ptcloud):
        """
        input           ptcloud:    sensor_msgs.msg PointCloud2
        output          points:     List of namedtuples containing the values for each point
        description     - before reading the points from the ptcloud the datatype of the RGB values is changed
                            from fields[3].datatype = 7(FLOAT32) to fields[3].datatype = 6(UINT32), as the data
                            is damaged when reading in float as all values that start with nine 1's are read as NAN
                        - https://github.com/PointCloudLibrary/pcl/issues/1543 (simular issue is described here)
        """
        fields = ptcloud.fields
        fields[3].datatype = 6
        points = pc2.read_points_list(ptcloud, skip_nans=True)
        return points

    def generate_pointcloud(self,points=None):
        """
        input           points (optional) list, containing x,y,z,RBG of one point in each line
        output          ptcloud_merged: sensor_msgs.msg PointCloud2
        description     change fields[3].datatype back to 7 (FLOAT32)
        """
        header =  self.ptcloud.header
        header.frame_id = "/l_gripper_tool_frame"
        fields = self.ptcloud.fields
        #apparently 'ptcloud_merged.fields[3].datatype = 7' later changes also self.ptcloud.fields[3].datatype = 7
        #call by reference! in case of debugging it messes up the colors, thats why this line is needed
        fields[3].datatype = 6
        if not points:
            points = self.points
        ptcloud_merged = pc2.create_cloud(header, fields, points)
        ptcloud_merged.fields[3].datatype = 7
        return ptcloud_merged


if __name__ == "__main__":
    main()
