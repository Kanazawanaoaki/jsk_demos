#!/usr/bin/env python
# -*- coding: utf-8 -*-

import rospy
from audio_common_msgs.msg import AudioData
from sound_play.msg import SoundRequest, SoundRequestAction, SoundRequestGoal
import actionlib
import time
import numpy as np

class AudioChecker:
    def __init__(self):
        rospy.init_node('audio_checker', anonymous=True)
        self.mic_name = rospy.get_param('~mic_name', 'mke200')
        self.topic_name = rospy.get_param('~topic_name', '/mke200/audio')
        self.timeout_threshold = rospy.get_param('~timeout_threshold', 5.0)  # トピックが一定時間更新されなかった場合の閾値（秒）

        self.no_topic_flag = False  # topicが来ていない状況ならTrue
        self.once_topic_flag = False  # topicが一度でも来ていたらTrue
        self.silence_flag = False  # 無音が続いているかのフラグ

        # Create an Action client for the sound_play node
        self.sound_client = actionlib.SimpleActionClient('/robotsound', SoundRequestAction)
        self.sound_client.wait_for_server()

        self.say_something("{} audio check start".format(self.mic_name))
        # トピックをサブスクライブ
        self.subscriber = rospy.Subscriber(self.topic_name, AudioData, self.audio_callback)

        # 最後にトピックが更新された時間
        self.last_topic_time = time.time()

    def audio_callback(self, msg):
        # トピックが更新されたら呼び出されるコールバック
        self.last_topic_time = time.time()
        if self.no_topic_flag or not self.once_topic_flag:
            self.no_topic_flag = False
            self.once_topic_flag = True
            self.say_something("{} audio topic is arriving.".format(self.mic_name))

        # 無音チェック（すべてのデータが0かどうか）
        audio_data = np.frombuffer(msg.data, dtype=np.uint8)
        if np.all(audio_data == 0):
            if not self.silence_flag:
                if not self.silence_flag:
                    self.say_something("{} audio topic contains only silence.".format(self.mic_name))
                    self.silence_flag = True
        else:
            self.silence_flag = False

    def check_timeout(self):
        # 一定時間以上トピックが更新されていないかチェック
        if time.time() - self.last_topic_time > self.timeout_threshold:
            if self.no_topic_flag:
                return
            else:
                self.no_topic_flag = True
                self.say_something("I haven't seen the {} audio topic for {} seconds.".format(self.topic_name, self.timeout_threshold))

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
        audio_checker = AudioChecker()
        audio_checker.run()
    except rospy.ROSInterruptException:
        pass
