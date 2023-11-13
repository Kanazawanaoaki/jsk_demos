#!/usr/bin/env python

import rospy
from ros_speak import speak_jp


if __name__ == '__main__':
    speak_jp(' ', wait=True)
    rospy.sleep(5.0)
    speak_jp('サウンドプレイ、起動しました', wait=False)
    rospy.sleep(5.0)
