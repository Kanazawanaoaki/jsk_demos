#!/usr/bin/env python
import rospy
from sensor_msgs.msg import Image
from std_msgs.msg import String
import time

class ImageSubscriber:
    def __init__(self):
        rospy.init_node('image_subscriber_node', anonymous=True)

        # イメージメッセージをサブスクライブ
        self.image_sub = rospy.Subscriber('/k4a/rgb/image_rect_color', Image, self.image_callback)

        # ロボットに話させるためのトピック
        self.robot_talk_topic = '/robot/talk'
        self.robot_talk_pub = rospy.Publisher(self.robot_talk_topic, String, queue_size=10)

        # トピックが一定時間更新されなかった場合の閾値（秒）
        self.timeout_threshold = 1.0

        # 最後にトピックが更新された時間
        self.last_image_time = time.time()

    def image_callback(self, msg):
        # トピックが更新されたら呼び出されるコールバック
        self.last_image_time = time.time()

    def check_timeout(self):
        # 一定時間以上トピックが更新されていないかチェック
        if time.time() - self.last_image_time > self.timeout_threshold:
            self.say_something("I haven't seen any images for a while.")

    def say_something(self, text):
        # ロボットに喋らせる
        rospy.loginfo(text)
        self.robot_talk_pub.publish(String(text))

    def run(self):
        rate = rospy.Rate(1)  # ループレート：1 Hz
        while not rospy.is_shutdown():
            self.check_timeout()
            rate.sleep()

if __name__ == '__main__':
    try:
        image_subscriber = ImageSubscriber()
        image_subscriber.run()
    except rospy.ROSInterruptException:
        pass
