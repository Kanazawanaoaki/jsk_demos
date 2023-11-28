#!/usr/bin/env python

from ros_speak import speak_jp
import rospy


if __name__ == '__main__':
    speak_jp(' ', wait=True)
    rospy.sleep(5.0)
    volume = rospy.get_param('~volume', 0.1)
    speak_jp('サウンドプレイ、起動しました', wait=False,
             volume=volume)
    rospy.sleep(5.0)
