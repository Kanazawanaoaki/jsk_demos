#!/usr/bin/env python
# -*- coding: utf-8 -*-

import rospy
from std_msgs.msg import UInt16
from sound_play.msg import SoundRequest, SoundRequestAction, SoundRequestGoal
import actionlib
import time

class UInt16TopicChecker:
    def __init__(self):
        rospy.init_node('uint16_topic_checker', anonymous=True)
        self.topic_name = rospy.get_param('~topic_name', '/tgs_2600_analog')
        self.timeout_threshold = rospy.get_param('~timeout_threshold', 5.0)  # トピックが一定時間更新されなかった場合の閾値（秒）

        self.no_topic_flag = False  # topicが来ていない状況ならTrue
        self.once_topic_flag = False  # topicが一度でも来ていたらTrue

        # Create an Action client for the sound_play node
        self.sound_client = actionlib.SimpleActionClient('/robotsound', SoundRequestAction)
        self.sound_client.wait_for_server()

        self.say_something("{} topic check start".format(self.topic_name))
        # トピックをサブスクライブ
        self.subscriber = rospy.Subscriber(self.topic_name, UInt16, self.topic_callback)

        # 最後にトピックが更新された時間
        self.last_topic_time = time.time()

    def topic_callback(self, msg):
        # トピックが更新されたら呼び出されるコールバック
        self.last_topic_time = time.time()
        if self.no_topic_flag or not self.once_topic_flag:
            self.no_topic_flag = False
            self.once_topic_flag = True
            self.say_something("{} topic is arriving.".format(self.topic_name))

    def check_timeout(self):
        # 一定時間以上トピックが更新されていないかチェック
        if time.time() - self.last_topic_time > self.timeout_threshold:
            if self.no_topic_flag:
                return
            else:
                self.no_topic_flag = True
                self.say_something("I haven't seen the {} topic for {} seconds.".format(self.topic_name, self.timeout_threshold))

    def say_something(self, text):
        # ロボットに喋らせる
        rospy.loginfo(text)

        # Create a SoundRequestGoal message
        sound_goal = SoundRequestGoal()
        sound_goal.sound_request.sound = SoundRequest.SAY
        sound_goal.sound_request.command = SoundRequest.PLAY_ONCE
        sound_goal.sound_request.volume = 1.0
        sound_goal.sound_request.arg = text

        # Send the SoundRequestGoal to the sound_play node
        self.sound_client.send_goal(sound_goal)

        # Wait for the result (you can add timeout if needed)
        self.sound_client.wait_for_result()

    def run(self):
        rate = rospy.Rate(1)  # ループレート：1 Hz
        while not rospy.is_shutdown():
            self.check_timeout()
            rate.sleep()

if __name__ == '__main__':
    try:
        topic_checker = UInt16TopicChecker()
        topic_checker.run()
    except rospy.ROSInterruptException:
        pass
