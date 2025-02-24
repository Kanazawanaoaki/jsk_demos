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
        # translation = (0.175, 0, 0.025)  # 例えば、x、y、zは適切な値に置き換える必要があります

        # translation = (0.160, -0.04, -0.010)  # 例えば、x、y、zは適切な値に置き換える必要があります
        # rotation = (0, 0, 0, 1)  # 回転の場合も同様です

        ## ARマーカで修正１
        # translation = (0.1507, 0.0108, 0.0514)  # 例えば、x、y、zは適切な値に置き換える必要があります
        # rotation = (0, 0, 0, 1)  # 回転の場合も同様です

        # ## ARマーカで修正２
        # translation = (0.1578, 0.0041, 0.0146)  # 例えば、x、y、zは適切な値に置き換える必要があります
        # rotation = (0, 0, 0, 1)  # 回転の場合も同様です

        # ## ARマーカで修正３ 後日
        # translation = (0.1411, 0.0057, 0.0331)  # 例えば、x、y、zは適切な値に置き換える必要があります
        # rotation = (0.008609, 0.017081, 0.00135, 0.999816)  # 回転の場合も同様です

        ## ARマーカで修正４ 後日
        translation = (0.1768, 0.0086, 0.0039)  # 例えば、x、y、zは適切な値に置き換える必要があります
        rotation = (0.004946, -0.00796, -0.000587, 0.999956)  # 回転の場合も同様です

        broadcaster.sendTransform(
            translation,
            rotation,
            rospy.Time.now(),
            'femto_mega_link',
            'head_mount_link'
        )

        rate.sleep()

if __name__ == '__main__':
    try:
        broadcast_tf()
    except rospy.ROSInterruptException:
        pass
