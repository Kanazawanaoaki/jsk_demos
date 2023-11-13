import rospy
import actionlib
import actionlib_msgs.msg

from jsk_teaching_object.msg import TakeImagePhotoAction
from jsk_teaching_object.msg import TakeImagePhotoGoal


_clients = {}


def take_image_photo(topic_name, image_topic_name, save_path, wait=True,
                     timeout=rospy.Duration()):
    if topic_name in _clients:
        client = _clients[topic_name]
    else:
        client = actionlib.SimpleActionClient(
            topic_name,
            TakeImagePhotoAction)
    client.wait_for_server()

    goal = TakeImagePhotoGoal()
    if client.get_state() == actionlib_msgs.msg.GoalStatus.ACTIVE:
        client.cancel_goal()
        client.wait_for_result(timeout=rospy.Duration(10))
    goal.save_path = save_path
    goal.image_topic_name = image_topic_name
    _clients[topic_name] = client
    client.send_goal(goal)

    if wait is True:
        client.wait_for_result(timeout=timeout)
    return client


if __name__ == '__main__':
    rospy.init_node('take_image_photo_client')
    take_image_photo('/r8_5_look_server/take_image_photo',
                     '/usb_cam/image_raw',
                     '/home/iory/dataset/project_t/2023-09-21/tmp')
