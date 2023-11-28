import actionlib
import actionlib_msgs.msg
from jsk_teaching_object.msg import UpdateModelAction
from jsk_teaching_object.msg import UpdateModelGoal
import rospy


_update_model_clients = {}


def update_model(topic_name, model_path, class_name_path,
                 wait=True):
    if topic_name in _update_model_clients:
        client = _update_model_clients[topic_name]
    else:
        client = actionlib.SimpleActionClient(
            topic_name,
            UpdateModelAction)
    client.wait_for_server()

    goal = UpdateModelGoal()
    if client.get_state() == actionlib_msgs.msg.GoalStatus.ACTIVE:
        client.cancel_goal()
        client.wait_for_result(timeout=rospy.Duration(10))
    goal.model_path = model_path
    _update_model_clients[topic_name] = client
    client.send_goal(goal)

    if wait is True:
        client.wait_for_result(timeout=rospy.Duration(10))
    return client
