import rospy
import actionlib
import actionlib_msgs.msg

from jsk_teaching_object.msg import TakeActionAction
from jsk_teaching_object.msg import TakeActionGoal


_clients = {}


def take_action(topic_name, wait=True,
                timeout=rospy.Duration()):
    if topic_name in _clients:
        client = _clients[topic_name]
    else:
        client = actionlib.SimpleActionClient(
            topic_name,
            TakeActionAction)
    client.wait_for_server()

    goal = TakeActionGoal()
    if client.get_state() == actionlib_msgs.msg.GoalStatus.ACTIVE:
        client.cancel_goal()
        client.wait_for_result(timeout=rospy.Duration(10))
    _clients[topic_name] = client
    client.send_goal(goal)

    if wait is True:
        client.wait_for_result(timeout=timeout)
    return client
