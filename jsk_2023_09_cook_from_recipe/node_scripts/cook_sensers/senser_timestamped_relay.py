#!/usr/bin/env python

import rospy
from std_msgs.msg import UInt16
from jsk_2023_09_cook_from_recipe.msg import TimestampedUInt16

class TimestampedPublisher:
    def __init__(self):
        # Subscriberでstd_msgs/UInt16を受け取る
        self.sub = rospy.Subscriber('~input_topic', UInt16, self.callback)
        # カスタムメッセージをpublishする
        self.pub = rospy.Publisher('~output_topic', TimestampedUInt16, queue_size=10)

    def callback(self, msg):
        # TimestampedUInt16メッセージを作成
        timestamped_msg = TimestampedUInt16()
        timestamped_msg.header.stamp = rospy.Time.now()  # 現在のタイムスタンプ
        # timestamped_msg.data = msg.data
        timestamped_msg.data = msg

        # 新しいメッセージをpublish
        self.pub.publish(timestamped_msg)

if __name__ == '__main__':
    rospy.init_node('timestamped_publisher')
    node = TimestampedPublisher()
    rospy.spin()
