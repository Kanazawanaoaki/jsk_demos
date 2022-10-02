#! /usr/bin/env python

import roslib; roslib.load_manifest('jsk_2022_09_fridge_pi')
import rospy
import actionlib

from jsk_2022_09_fridge_pi.msg import *

class DoDishesServer:
  def __init__(self):
    self.server = actionlib.SimpleActionServer('do_dishes', DoDishesAction, self.execute, False)
    self.server.start()

  def execute(self, goal):
    # Do lots of awesome groundbreaking robot stuff here
    print("execute!")
    # import ipdb
    # ipdb.set_trace()
    self.server.set_succeeded()


if __name__ == '__main__':
  rospy.init_node('do_dishes_server')
  server = DoDishesServer()
  rospy.spin()
