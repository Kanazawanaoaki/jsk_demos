#!/usr/bin/env python
# -*- coding: utf-8 -*-

import rospy
from sensor_msgs.msg import Image, CompressedImage, LaserScan
from sound_play.msg import SoundRequest, SoundRequestAction, SoundRequestGoal
import actionlib
import time

class BaseScanChecker:
    def __init__(self):
        rospy.init_node('base_scan_checker_node', anonymous=True)
        self.no_topic_flag = True

        # トピックをサブスクライブ
        self.topic_sub = rospy.Subscriber('/base_scan', LaserScan, self.topic_callback)

        # Create an Action client for the sound_play node
        self.sound_client = actionlib.SimpleActionClient('/robotsound', SoundRequestAction)
        self.sound_client.wait_for_server()

        # トピックが一定時間更新されなかった場合の閾値（秒）
        self.timeout_threshold = 5.0

        # 最後にトピックが更新された時間
        self.last_image_time = time.time()

        self.say_something("base scan check start")

    def topic_callback(self, msg):
        # トピックが更新されたら呼び出されるコールバック
        self.last_image_time = time.time()
        if self.no_topic_flag:
            self.no_topic_flag = False
            self.say_something("Base scan topic is arrive.")
        # rospy.loginfo("Recieve base scan topic !!")

    def check_timeout(self):
        # 一定時間以上トピックが更新されていないかチェック
        if time.time() - self.last_image_time > self.timeout_threshold:
            if self.no_topic_flag:
                return
            else:
                self.no_topic_flag = True
                self.say_something("I haven't seen the base scan topic for {} seconds.".format(self.timeout_threshold))
        # else:
            # if self.no_topic_flag:
            #     self.no_topic_flag = False
                # self.say_something("Base scan topic is arrive.")

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
        topic_checker = BaseScanChecker()
        topic_checker.run()
    except rospy.ROSInterruptException:
        pass
