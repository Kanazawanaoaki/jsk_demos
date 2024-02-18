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
        # head_mount_linkからcamera_baseへの座標変換を指定
        translation = (0.175, 0, 0.025)  # 例えば、x、y、zは適切な値に置き換える必要があります
        rotation = (0, 0, 0, 1)  # 回転の場合も同様です

        broadcaster.sendTransform(
            translation,
            rotation,
            rospy.Time.now(),
            'camera_base',
            'head_mount_link'
        )

        rate.sleep()

if __name__ == '__main__':
    try:
        broadcast_tf()
    except rospy.ROSInterruptException:
        pass
