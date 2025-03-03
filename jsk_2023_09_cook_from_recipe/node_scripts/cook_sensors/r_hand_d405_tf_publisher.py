#!/usr/bin/env python
# -*- coding: utf-8 -*-

import rospy
import tf
from geometry_msgs.msg import TransformStamped

def broadcast_tf():
    rospy.init_node('tf_broadcaster')

    broadcaster = tf.TransformBroadcaster()

    rate = rospy.Rate(10.0)  # ブロードキャストの周波数

    while not rospy.is_shutdown():
        translation = (0.135662, 0.010677, -0.108754)  # 例えば、x、y、zは適切な値に置き換える必要があります
        rotation = (0.922931, -0.003779, 0.384939, -0.002482)  # 回転の場合も同様です
        # rotation = (0.8660254, 0.0, 0.5, 0.0)  # 回転の場合も同様です
        # rotation = (0.85286853, 0.08682409, -0.49240388, -0.15038373)  # 回転の場合も同様です

        # translation = (0.0, 0.0, 0.0)  # 例えば、x、y、zは適切な値に置き換える必要があります
        # rotation = (0.0, 0.0, 0.0, 1)  # 回転の場合も同様です

        broadcaster.sendTransform(
            translation,
            rotation,
            rospy.Time.now(),
            'r_hand_d405_link',
            'r_gripper_palm_link'
        )
        # broadcaster.sendTransform(
        #     translation,
        #     rotation,
        #     rospy.Time.now(),
        #     'r_hand_d405_link',
        #     'tf2'
        # )

        rate.sleep()

if __name__ == '__main__':
    try:
        broadcast_tf()
    except rospy.ROSInterruptException:
        pass
