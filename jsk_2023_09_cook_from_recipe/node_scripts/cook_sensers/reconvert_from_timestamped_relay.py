#!/usr/bin/env python

import rospy
from std_msgs.msg import UInt16
from jsk_2023_09_cook_from_recipe.msg import TimestampedUInt16

class ReconvertUInt16Publisher:
    def __init__(self):
        # Subscriberでstd_msgs/UInt16を受け取る
        self.sub = rospy.Subscriber('~input_topic', TimestampedUInt16, self.callback)
        # カスタムメッセージをpublishする
        self.pub = rospy.Publisher('~output_topic', UInt16, queue_size=10)

    def callback(self, msg):
        # TimestampedUInt16メッセージを作成
        uint_msg = UInt16()
        uint_msg.data = msg.data.data

        # 新しいメッセージをpublish
        self.pub.publish(uint_msg)

if __name__ == '__main__':
    rospy.init_node('reconvert_unit16_publisher')
    node = ReconvertUInt16Publisher()
    rospy.spin()
