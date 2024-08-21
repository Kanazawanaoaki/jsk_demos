#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys,subprocess,traceback
import rospy
import time
import os
from sensor_msgs.msg import Image, CompressedImage, LaserScan
from sound_play.msg import SoundRequest, SoundRequestAction, SoundRequestGoal
import actionlib

class HokuyoScanChecker:
    def __init__(self):
        rospy.init_node('hokuyo_scan_checker_node', anonymous=True)
        self.no_topic_flag = False ## topicが来ていない状況ならTrue
        self.once_topic_flag = False ## topicが一度でも来ていたらTrue

        self.hokuyo_name = rospy.get_param('~hokuyo_name', 'base')

        # Create an Action client for the sound_play node
        self.sound_client = actionlib.SimpleActionClient('/robotsound', SoundRequestAction)
        self.sound_client.wait_for_server()

        # トピックが一定時間更新されなかった場合の閾値（秒）
        self.timeout_threshold = 10.0

        # 最後にトピックが更新された時間
        self.last_image_time = time.time()

        self.say_something("base scan check start")

        # トピックをサブスクライブ
        self.topic_sub = rospy.Subscriber('/base_scan', LaserScan, self.topic_callback)
        self.launch_process = None

    def topic_callback(self, msg):
        # トピックが更新されたら呼び出されるコールバック
        self.last_image_time = time.time()
        if self.no_topic_flag or self.once_topic_flag==False:
            self.no_topic_flag = False
            self.once_topic_flag = True
            self.say_something("Base scan topic is arrive.")

    def check_timeout(self):
        # 一定時間以上トピックが更新されていないかチェック
        if time.time() - self.last_image_time > self.timeout_threshold:
            if self.no_topic_flag:
                return
            else:
                self.no_topic_flag = True
                self.say_something("I haven't seen the base scan topic for {} seconds.".format(self.timeout_threshold))
                self.restart_hokuyo()

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

    def restart_hokuyo(self):
        rospy.logerr("Restart base hokuyo")
        retcode = -1
        if self.launch_process:
            self.launch_process.terminate() ## launchを強制終了
            self.launch_process.wait()
        try:
            # 1. kill base hokuyo node
            retcode = subprocess.call('rosnode kill /base_hokuyo_node', shell=True)
            retcode = subprocess.call('pkill -f base_hokuyo_node', shell=True)
            rospy.loginfo("Killed base hokuyo node")
            time.sleep(10)

            # 2. reset hokuyo
            retcode = subprocess.call('./upgrade /etc/ros/sensors/base_hokuyo reset.cmd', shell=True)
            rospy.loginfo("Reset hokuyo")
            time.sleep(10)

            # 3 Restarting base hokuyo node
            self.launch_process = subprocess.Popen(['roslaunch', 'base_hokuyo_test.launch'])
            rospy.loginfo("Restart base hokuyo node")
            time.sleep(30)

        except Exception as e:
            rospy.logerr('[%s] Unable to kill base hokuyo node, caught exception:\n%s', self.__class__.__name__, traceback.format_exc())

    def run(self):
        rate = rospy.Rate(1)  # ループレート：1 Hz
        while not rospy.is_shutdown():
            self.check_timeout()
            rate.sleep()

if __name__ == '__main__':
    try:
        topic_checker = HokuyoScanChecker()
        topic_checker.run()
    except rospy.ROSInterruptException:
        pass
