#!/usr/bin/env python
# -*- coding: utf-8 -*-

from jsk_2022_09_fridge_pi.srv import FridgePiOrder, FridgePiOrderResponse
import rospy

def check_task_executable(task, message):
    # check task executable with robot state
    return True

def order_do_task(task, message):
    # do task
    return True

def firdge_pi_task(req):
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
    rospy.init_node('firdge_pi_task_server')
    s = rospy.Service('firdge_pi_task', FridgePiOrder, firdge_pi_task)

    # spin() keeps Python from exiting until node is shutdown
    rospy.spin()
