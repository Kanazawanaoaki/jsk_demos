#!/usr/bin/env python
# -*- coding: utf-8 -*-

import rospy
from sensor_msgs.msg import Image, CompressedImage
from sound_play.msg import SoundRequest, SoundRequestAction, SoundRequestGoal
import actionlib
import time

class ImageChecker:
    def __init__(self):
        rospy.init_node('image_topic_checker', anonymous=True)
        self.camera_name = rospy.get_param('~camera_name', 'femto_mega')
        self.image_topic = rospy.get_param('~image_topic', '/femto_mega/color/image_raw')
        self.timeout_threshold = rospy.get_param('~timeout_threshold', 5.0) # トピックが一定時間更新されなかった場合の閾値（秒）

        self.no_topic_flag = False ## topicが来ていない状況ならTrue
        self.once_topic_flag = False ## topicが一度でも来ていたらTrue

        # Create an Action client for the sound_play node
        self.sound_client = actionlib.SimpleActionClient('/robotsound', SoundRequestAction)
        self.sound_client.wait_for_server()

        # トピックが一定時間更新されなかった場合の閾値（秒）
        # self.timeout_threshold = 5.0

        self.say_something("{} image check start".format(self.camera_name))
        # イメージメッセージをサブスクライブ
        self.image_sub = rospy.Subscriber(self.image_topic, Image, self.image_callback)

        # 最後にトピックが更新された時間
        self.last_image_time = time.time()


    def image_callback(self, msg):
        # トピックが更新されたら呼び出されるコールバック
        self.last_image_time = time.time()
        if self.no_topic_flag or self.once_topic_flag==False:
            self.no_topic_flag = False
            self.once_topic_flag = True
            self.say_something("{} image topic is arrive.".format(self.camera_name))

    def check_timeout(self):
        # 一定時間以上トピックが更新されていないかチェック
        if time.time() - self.last_image_time > self.timeout_threshold:
            if self.no_topic_flag:
                return
            else:
                self.no_topic_flag = True
                self.say_something("I haven't seen the {} image topic for {} seconds.".format(self.camera_name, self.timeout_threshold))

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
        image_checker = ImageChecker()
        image_checker.run()
    except rospy.ROSInterruptException:
        pass
