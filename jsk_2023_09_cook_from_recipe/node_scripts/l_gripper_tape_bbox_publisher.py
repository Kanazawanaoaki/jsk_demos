#!/usr/bin/env python

import rospy
from jsk_recognition_msgs.msg import BoundingBox, BoundingBoxArray
from geometry_msgs.msg import Pose, Point, Quaternion
import tf.transformations

def create_bounding_box(center, dimensions, orientation, frame_id):
    box = BoundingBox()
    box.pose.position = center
    box.pose.orientation = orientation
    box.dimensions.x = dimensions[0]
    box.dimensions.y = dimensions[1]
    box.dimensions.z = dimensions[2]
    box.header.frame_id = frame_id
    return box

def publish_bounding_boxes():
    rospy.init_node('l_gripper_tape_bounding_box_publisher', anonymous=True)
    pub = rospy.Publisher('l_gripper_tape_bounding_boxes', BoundingBoxArray, queue_size=10)
    rate = rospy.Rate(10) # 10 Hz

    while not rospy.is_shutdown():
        frame_id = 'l_gripper_tool_frame'
        bbox_array = BoundingBoxArray()
        bbox_array.header.frame_id = frame_id
        bbox_array.header.stamp = rospy.Time.now()

        ## left tape
        # ダミーのバウンディングボックスの作成
        frame_id = 'l_gripper_tool_frame'
        center = Point(-0.090, 0.055, 0.0)
        dimensions = [0.035, 0.003, 0.015]
        quaternion = tf.transformations.quaternion_from_euler(0, -1.5708, 0) # -90度
        orientation = Quaternion(*quaternion)
        bbox = create_bounding_box(center, dimensions, orientation, frame_id)

        bbox_array.boxes.append(bbox)

        ## right taple
        # ダミーのバウンディングボックスの作成
        frame_id = 'l_gripper_tool_frame'
        center = Point(-0.090, -0.055, 0.0)
        dimensions = [0.035, 0.003, 0.015]
        quaternion = tf.transformations.quaternion_from_euler(0, -1.5708, 0) # -90度
        orientation = Quaternion(*quaternion)
        bbox = create_bounding_box(center, dimensions, orientation, frame_id)

        bbox_array.boxes.append(bbox)

        ## lower tape
        # ダミーのバウンディングボックスの作成
        frame_id = 'l_gripper_tool_frame'
        center = Point(-0.122, 0.0, 0.023)
        dimensions = [0.01, 0.003, 0.02]
        quaternion = tf.transformations.quaternion_from_euler(1.5708, 0, 0) # 90度
        orientation = Quaternion(*quaternion)
        bbox = create_bounding_box(center, dimensions, orientation, frame_id)

        bbox_array.boxes.append(bbox)

        ## upper tape
        # ダミーのバウンディングボックスの作成
        frame_id = 'l_gripper_tool_frame'
        center = Point(-0.127, 0.0, -0.023)
        dimensions = [0.01, 0.003, 0.02]
        quaternion = tf.transformations.quaternion_from_euler(1.5708, 0, 0) # 90度
        orientation = Quaternion(*quaternion)
        bbox = create_bounding_box(center, dimensions, orientation, frame_id)

        bbox_array.boxes.append(bbox)

        pub.publish(bbox_array)
        rate.sleep()

if __name__ == '__main__':
    try:
        publish_bounding_boxes()
    except rospy.ROSInterruptException:
        pass
