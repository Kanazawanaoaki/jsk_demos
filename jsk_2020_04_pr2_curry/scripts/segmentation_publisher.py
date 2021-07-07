#!/usr/bin/env python

import rospy
from jsk_recognition_msgs.msg import BoundingBoxArray , BoundingBox

def talker():
    pub = rospy.Publisher('/segmentation_decomposer/boxes', BoundingBoxArray, queue_size=10)
    rospy.init_node('segmentation_talker', anonymous=True)
    rate = rospy.Rate(10)
    while not rospy.is_shutdown():
        b = BoundingBoxArray()
        b.header.frame_id  = "/head_mount_kinect_rgb_optical_frame"
        b.header.stamp = rospy.get_rostime()
        b1 = BoundingBox()
        # b1.header.frame_id  = "/head_mount_kinect_rgb_optical_frame"
        # b1.header.stamp = rospy.get_rostime()
        b1.header = b.header
        b1.pose.position.x = 0.1
        b1.pose.position.y = 0.1
        b1.pose.position.z = 0.1
        b1.dimensions.x = 0.15
        b1.dimensions.y = 0.06
        b1.dimensions.z = 0.06
        b.boxes = [b1]
        pub.publish(b)
        rate.sleep()


if __name__ == '__main__':
    try:
        talker()
    except rospy.ROSInterruptException:
        pass
        
