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
        # ## インタラクティブマーカで手動合わせした座標
        # translation = (0.135662, 0.010677, -0.108754)  # 例えば、x、y、zは適切な値に置き換える必要があります
        # rotation = (0.922931, -0.003779, 0.384939, -0.002482)  # 回転の場合も同様です

        # translation = (0.0, 0.0, 0.0)  # 例えば、x、y、zは適切な値に置き換える必要があります
        # rotation = (0.0, 0.0, 0.0, 1)  # 回転の場合も同様です

        # ## キャリブで計算してみた
        # translation = (0.097993, -0.028103, -0.114784)  # 例えば、x、y、zは適切な値に置き換える必要があります
        # rotation = (0.941935, 0.019088, 0.335225, -0.00423)  # 回転の場合も同様です

        # ## キャリブ v2 コンロ操作近く
        # translation = (0.112101, -0.017437, -0.103896)  # 例えば、x、y、zは適切な値に置き換える必要があります
        # rotation = (0.941017, -0.012594, 0.338038, 0.007634)  # 回転の場合も同様です

        ## キャリブ v3  reset-cook-poseで調整，しばらくはこれを使う！！！
        translation = (0.119095, -0.009747, -0.096833)  # 例えば、x、y、zは適切な値に置き換える必要があります
        rotation = (0.930095, 0.000498, 0.367294, 0.004271)  # 回転の場合も同様です

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
