#!/usr/bin/env python
# -*- coding: utf-8 -*-

from jsk_2022_09_fridge_pi.srv import FridgePiOrder, FridgePiOrderRequest
import rospy

def firdge_pi_task_client(task, message):
    try:
        # create a handle to the add_two_ints service
        firdge_pi_task = rospy.ServiceProxy('firdge_pi_task', FridgePiOrder)

        print("Requesting %s, %s"%(task, message))

        # simplified style
        resp1 = firdge_pi_task(task, message)

        # # formal style
        # resp2 = firdge_pi_task.call(FridgePiOrderRequest(task, message))

        print("result : {}".format(resp1.success))
        print("message : {}".format(resp1.message))
        # print("result {}".format(resp2.success))
        # print("message {}".format(resp2.message))

    except rospy.ServiceException, e:
        print("Service call failed: %s"%e)

if __name__ == "__main__":
    rospy.init_node('firdge_pi_task_client')
    rospy.wait_for_service('firdge_pi_task')
    firdge_pi_task_client("test", "test message")
