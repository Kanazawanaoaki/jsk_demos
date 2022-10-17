#!/usr/bin/env python
# -*- coding: utf-8 -*-

import rospy
import roslibpy
import time
from pr2_msgs.msg import PowerState

class rosbridge_client:
    def __init__(self):
        rospy.init_node('pr2_state_publisher', anonymous=True)
        # self.ros_client = roslibpy.Ros('133.11.216.106', 9090)
        self.ros_client = roslibpy.Ros('133.11.216.67', 9090)
        print("wait for server")
        self.publisher = roslibpy.Topic(
            self.ros_client, '/pr2_robot_state', 'std_msgs/Bool')
        self.ros_client.run()

        self.sub = rospy.Subscriber("/power_state", PowerState, self.power_cb)
        rospy.spin()

    def power_cb(self, msg):
        now_ac = msg.AC_present
        print("current AC_persent : {}".format(now_ac))
        if now_ac > 0: # not movable
            self.pub_topic(False)
            time.sleep(0.5)
        else: # movable
            self.pub_topic(True)
            time.sleep(0.5)

    def pub_topic(self, value):
        self.publisher.publish(roslibpy.Message({'data': value}))


if __name__ == '__main__':
    rosbridge_client()
