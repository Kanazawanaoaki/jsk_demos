#! /usr/bin/env python

import roslib; roslib.load_manifest('jsk_2022_09_fridge_pi')
import rospy
import actionlib

from jsk_2022_09_fridge_pi.msg import *

if __name__ == '__main__':
    rospy.init_node('do_dishes_client')
    client = actionlib.SimpleActionClient('do_dishes', DoDishesAction)
    client.wait_for_server()

    goal = DoDishesGoal()
    print(goal)
    # Fill in the goal here
    client.send_goal(goal)
    result = client.wait_for_result(rospy.Duration.from_sec(5.0))
    print(result)
