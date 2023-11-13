#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import print_function

import os
import readline
import rospy
import sys
import std_msgs.msg
from collections import deque

from sound_play.msg import SoundRequest
from std_msgs.msg import ColorRGBA
from std_msgs.msg import Float32
from sound_play.msg import SoundRequestActionGoal
from speech_recognition_msgs.msg import SpeechRecognitionCandidates
from jsk_rviz_plugins.msg import OverlayText

try:
    input = raw_input
except NameError:
    pass


HISTORY = os.path.expanduser("~/.speech_history")
PROMPT = "{talker:<6}: "
pub = None

text = OverlayText()
text.width = 400
text.height = 100
text.left = 10
text.top = 10
text.text_size = 12
text.line_width = 2
text.font = "DejaVu Sans Mono"
text.fg_color = ColorRGBA(25 / 255.0, 1.0, 240.0 / 255.0, 1.0)
text.bg_color = ColorRGBA(0.0, 0.0, 0.0, 0.2)


history = deque(maxlen=4)

def speech_cb(msg):
    global history
    global pub
    if isinstance(msg, SoundRequestActionGoal):
        return speech_cb(msg.goal.sound_request)
    if msg.sound != SoundRequest.SAY:
        return
    history.append('robot: {}'.format(msg.arg))
    text.text = '\n'.join(list(history))
    pub.publish(text)


def speech_recognition_cb(msg):
    global history
    global pub
    history.append('person: {}'.format(msg.transcript[0]))
    text.text = '\n'.join(list(history))
    pub.publish(text)


def on_shutdown():
    readline.write_history_file(HISTORY)


def subscribe():
    subs = []
    topics = rospy.get_published_topics()
    t = filter(lambda t: t[1] == SoundRequest._type, topics)
    for name, type in t:
        sub = rospy.Subscriber(name, SoundRequest, speech_cb)
        subs.append(sub)
    t = filter(lambda t: t[1] == SoundRequestActionGoal._type, topics)
    for name, type in t:
        sub = rospy.Subscriber(name, SoundRequestActionGoal, speech_cb)
        subs.append(sub)
    subs.append(
        rospy.Subscriber(
            '/speech_to_text', SpeechRecognitionCandidates,
            callback=speech_recognition_cb,
            queue_size=1))
    return subs


def main():
    global pub
    rospy.init_node("publish_text")
    pub = rospy.Publisher('publish_text',
                          OverlayText,
                          queue_size=1)
    rospy.sleep(3.0)
    rospy.on_shutdown(on_shutdown)

    subscribe()
    rospy.spin()


if __name__ == '__main__':
    main()
