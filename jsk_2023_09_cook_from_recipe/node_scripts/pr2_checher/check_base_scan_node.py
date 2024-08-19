#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys,subprocess,traceback
import rospy
import time
import os
from sensor_msgs.msg import Image, CompressedImage, LaserScan
from sound_play.msg import SoundRequest, SoundRequestAction, SoundRequestGoal
import actionlib

class BaseScanChecker:
    def __init__(self):
        rospy.init_node('base_scan_checker_node', anonymous=True)
        self.no_topic_flag = True

        self.hokuyo_name = rospy.get_param('~hokuyo_name', 'base')

        # Create an Action client for the sound_play node
        self.sound_client = actionlib.SimpleActionClient('/robotsound', SoundRequestAction)
        self.sound_client.wait_for_server()

        # トピックが一定時間更新されなかった場合の閾値（秒）
        self.timeout_threshold = 5.0

        # 最後にトピックが更新された時間
        self.last_image_time = time.time()

        self.say_something("base scan check start")

        # トピックをサブスクライブ
        self.topic_sub = rospy.Subscriber('/base_scan', LaserScan, self.topic_callback)

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

    def restart_hokuyo(self):
        rospy.logerr("Restart base hokuyo")
        retcode = -1
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
            retcode = subprocess.call('roslaunch base_hokuyo_test.launch', shell=True)
            rospy.loginfo("Restart base hokuyo node")

            # # 3. usbreset...
            # self.say_something("resetting base hokuyo")
            # p = subprocess.Popen("lsusb", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            # stdout, stderr = p.communicate()
            # lines = stdout.decode('utf-8').split("\n")
            # ms_line = [l for l in lines if "Microsoft" in l][0]
            # # it should be like Bus 002 Device 013: ID 045e:02ad Microsoft Corp. Xbox NUI Audio
            # bus_id = ms_line.split(' ')[1]
            # bus_device_dir = "/dev/bus/usb/" + bus_id
            # files = os.listdir(bus_device_dir)
            # for f in files:
            #     full_path = os.path.join(bus_device_dir, f)
            #     if os.access(full_path, os.W_OK):
            #         retcode = subprocess.call('rosrun openni2_camera usb_reset ' + full_path, shell=True)
            # time.sleep(10)
            # # 1. kill nodelet manager
            # self.speak("something wrong with kinect, I'll restart it, killing nodelet manager")
            # retcode = subprocess.call('rosnode kill /%s/%s_nodelet_manager' % (self.camera, self.camera), shell=True)
            # retcode = subprocess.call('pkill -f %s_nodelet_manager' % self.camera, shell=True)


            # time.sleep(10)
            # 2. pkill
            # self.speak("killing child processes")
            # retcode = subprocess.call('pkill -f %s_nodelet_manager' % self.camera, shell=True)
            # time.sleep(10)
            # 3 restarting
            # self.speak("restarting processes")
            # retcode = subprocess.call('roslaunch openni_launch openni.launch camera:=%s publish_tf:=false depth_registration:=true rgb_processing:=false ir_processing:=false depth_processing:=false depth_registered_processing:=false disparity_processing:=false disparity_registered_processing:=false hw_registered_processing:=true sw_registered_processing:=false rgb_frame_id:=/head_mount_kinect_rgb_optical_frame depth_frame_id:=/head_mount_kinect_ir_optical_frame' % self.camera, shell=True)
        except Exception as e:
            rospy.logerr('[%s] Unable to kill base hokuyo node, caught exception:\n%s', self.__class__.__name__, traceback.format_exc())

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
