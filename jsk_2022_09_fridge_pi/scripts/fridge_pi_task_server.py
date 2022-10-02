#!/usr/bin/env python
# -*- coding: utf-8 -*-

from jsk_2022_09_fridge_pi.srv import FridgePiOrder, FridgePiOrderResponse, DemoOrder, DemoOrderRequest
from std_msgs.msg import String
import rospy

# import roslib; roslib.load_manifest('jsk_2022_09_fridge_pi')
# import actionlib
# from jsk_2022_09_fridge_pi.msg import *

# robot_state = "unmovable" # tmp not check in robot
robot_state = "standby"

def state_cb(msg):
    global robot_state
    robot_state = msg.data

def check_task_executable(task, message):
    # check task executable with robot state
    global robot_state
    print("[Check] current robot state is : {}".format(robot_state))
    if robot_state == "standby":
        # TODO check with task infomation (precondition? and planning?)
        return True
    else:
        return False

def order_do_task(task, message):
    # do task
    # goal = DoTasksGoal()
    # client.send_goal(goal)
    # result = client.wait_for_result(rospy.Duration.from_sec(5.0))
    # print(result)
    demo_name = "fridge_door_close_demo"
    fridge_pi_demo = rospy.ServiceProxy(demo_name, DemoOrder)

    print("Requesting %s, %s"%(task, message))

    # simplified style
    resp1 = fridge_pi_demo(task, message)

    print("result : {}".format(resp1.success))
    print("message : {}".format(resp1.message))
    return resp1.success

def fridge_pi_task(req):
    print("Requested task is {}".format(req.task))
    print("messeage : {}".format(req.message))
    res = FridgePiOrderResponse()
    # check task execution
    task_executable = check_task_executable(req.task, req.message)
    if task_executable:
        task_result = order_do_task(req.task, req.message)
        if task_result:
            res.success = True
            res.message = "Task of {} is done by robot.".format(req.task)
        else:
            res.success = False
            res.message = "Robot try task of {} but failed.".format(req.task)
    else:
        res.success = False
        res.message = "Robot is not in a state to perform task of {}.".format(req.task)
    return res

if __name__ == "__main__":
    rospy.init_node('fridge_pi_task_server')
    # sub = rospy.Subscriber("robot_state/state", String, state_cb) # tmp not check in robot
    service = rospy.Service('fridge_pi_task', FridgePiOrder, fridge_pi_task)
    # client = actionlib.SimpleActionClient('do_tasks', DoTaskAction)
    # client.wait_for_server()

    # spin() keeps Python from exiting until node is shutdown
    rospy.spin()
    # import ipdb
    # ipdb.set_trace()
