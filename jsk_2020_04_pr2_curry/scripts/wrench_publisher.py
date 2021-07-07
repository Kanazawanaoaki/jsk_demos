#!/usr/bin/env python

import rospy
from geometry_msgs.msg import WrenchStamped , Wrench

def talker():
    pub = rospy.Publisher('/right_endeffector/wrench', WrenchStamped, queue_size=10)
    rospy.init_node('wrench_talker', anonymous=True)
    rate = rospy.Rate(10)
    while not rospy.is_shutdown():
        w = WrenchStamped()
        w.header.frame_id  = "r_gripper_tool_frame"
        w.header.stamp = rospy.get_rostime()
        w.wrench.force.x = 0
        w.wrench.force.y = -15
        w.wrench.force.z = -10
        w.wrench.torque.x = 0
        w.wrench.torque.y = 0
        w.wrench.torque.z = 0
        pub.publish(w)
        rate.sleep()


if __name__ == '__main__':
    try:
        talker()
    except rospy.ROSInterruptException:
        pass
        
