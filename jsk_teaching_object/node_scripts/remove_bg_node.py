#!/usr/bin/env python
# -*- coding: utf-8 -*-

from cv_bridge import CvBridge
from jsk_topic_tools import ConnectionBasedTransport
import rospy
import cv2
import numpy as np

from sensor_msgs.msg import Image

import gdown
from jsk_teaching_object.remove_bg import remove_background
from rembg import remove
from jsk_teaching_object.put_text import put_text_to_image


class RemoveBGNode(ConnectionBasedTransport):

    def __init__(self):
        super(RemoveBGNode, self).__init__()
        self.classifier_name = rospy.get_param(
            "~classifier_name", rospy.get_name())

        self.cv_bridge = CvBridge()

        self.font_path = rospy.get_param(
            '~font_path',
            gdown.cached_download('https://github.com/googlefonts/noto-cjk/raw/main/Sans/OTF/Japanese/NotoSansCJKjp-Regular.otf'))
        self.label_size = 32
        self.pos = (10, 40)
        self.image_caption = rospy.get_param('~image_caption', 'Remove Background Image')

        self.pub_image = self.advertise("~output/image", Image,
                                        queue_size=1)
        self.pub_image_debug = self.advertise("~output/image/debug", Image,
                                              queue_size=1)
        self.pub_mask = self.advertise("~output/mask", Image,
                                       queue_size=1)

    def subscribe(self):
        self.sub_image = rospy.Subscriber(
            "~input",
            Image, self.image_cb,
            queue_size=1,
            buff_size=2 ** 24,
            tcp_nodelay=False)

    def unsubscribe(self):
        self.sub_image.unregister()

    def image_cb(self, msg):
        if (rospy.Time.now() - msg.header.stamp).to_sec() > 0.4:
            return
        try:
            # transform image to RGB, float, CHW
            img = self.cv_bridge.imgmsg_to_cv2(msg, desired_encoding="bgr8")
        except Exception as e:
            rospy.logerr("Failed to convert image: %s" % str(e))
            return

        try:
            # viz_img = remove_background(img)
            viz_img = remove(img)
            mask = viz_img[:, :, 3]
        except Exception as e:
            viz_img = np.zeros((img.shape[0], img.shape[1], 4), dtype=np.uint8)
            viz_img[:, :, :3] = img
            mask = np.zeros((img.shape[0], img.shape[1]), dtype=np.uint8)

        try:
            mask_msg = self.cv_bridge.cv2_to_imgmsg(mask, "mono8")
        except Exception as e:
            rospy.logerr("Failed to convert bbox image: %s" % str(e))
            return
        mask_msg.header = msg.header
        self.pub_mask.publish(mask_msg)

        try:
            viz_msg = self.cv_bridge.cv2_to_imgmsg(viz_img, "bgra8")
        except Exception as e:
            rospy.logerr("Failed to convert bbox image: %s" % str(e))
            return
        viz_msg.header = msg.header
        self.pub_image.publish(viz_msg)

        caption_image = np.zeros((100, viz_img.shape[1], 4), dtype=np.uint8)
        color = (127, 127, 127, 255)
        caption_image = put_text_to_image(
            caption_image, self.image_caption, (10, self.label_size + self.label_size / 2.0),
            self.font_path,
            self.label_size,
            color=(255, 255, 255),
            background_color=tuple(color),
            offset_x=10)
        canvas = np.concatenate([
            caption_image,
            viz_img,
        ], axis=0)
        try:
            viz_msg = self.cv_bridge.cv2_to_imgmsg(canvas, "bgra8")
        except Exception as e:
            rospy.logerr("Failed to convert bbox image: %s" % str(e))
            return
        viz_msg.header = msg.header
        self.pub_image_debug.publish(viz_msg)


if __name__ == '__main__':
    rospy.init_node("remove_bg_node")
    act = RemoveBGNode()
    rospy.spin()
