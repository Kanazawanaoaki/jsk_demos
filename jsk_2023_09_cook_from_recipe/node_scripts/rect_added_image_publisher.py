#!/usr/bin/env python
# -*- coding: utf-8 -*-

import cv2
from cv_bridge import CvBridge
import rospy
from sensor_msgs.msg import Image

from dynamic_reconfigure.server import Server
from jsk_2023_09_cook_from_recipe.cfg import CropConfig

class RectAddedImagePublisher():
    def __init__(self):
        rospy.init_node('rect_added_image_publisher')
        # self.input_topic = "/k4a/rgb/image_rect_color"
        # self.input_topic = rospy.get_param('~input', "/k4a/rgb/image_rect_color")
        self.input_topic = rospy.get_param('~input', "/k4a/rgb/image_decompress")

        # Initialize ros params
        self.offset_x = rospy.get_param('~offset_x', 1140)
        self.offset_y = rospy.get_param('~offset_y', 480)
        self.width = rospy.get_param('~width', 280)
        self.height = rospy.get_param('~height', 280)

        # dynamic reconfigure
        self._reconfigure_server = Server(CropConfig, self.config_cb)

        rospy.Subscriber(self.input_topic, Image, self.image_cb)
        self.crop_pub = rospy.Publisher('~crop_image', Image, queue_size=10)
        self.recet_added_pub = rospy.Publisher('~rect_added_image', Image, queue_size=10)

        # Initialize CvBridge
        self.bridge = CvBridge()

    def config_cb(self, config, level):
        self.offset_x = config.offset_x
        self.offset_y = config.offset_y
        self.width = config.width
        self.height = config.height
        print("offset_x is changed to {}".format(self.offset_x))
        print("offset_y is changed to {}".format(self.offset_y))
        print("width is changed to {}".format(self.width))
        print("height is changed to {}".format(self.height))
        return config

    def image_cb(self, msg):
        img = self.bridge.imgmsg_to_cv2(msg)
        header = msg.header
        cropped_img = img.copy()
        rect_added_img = img.copy()
        rect_added_img = cv2.rectangle(rect_added_img,
                                       pt1=(self.offset_x, self.offset_y),
                                       pt2=(self.offset_x + self.width, self.offset_y + self.height),
                                       color=(0, 255, 0),
                                       thickness=3)
        recet_added_pub_msg = self.bridge.cv2_to_imgmsg(rect_added_img, "bgra8")
        recet_added_pub_msg.header= header
        self.recet_added_pub.publish(recet_added_pub_msg)

        cropped_img = cropped_img[self.offset_y:self.offset_y+self.height, self.offset_x:self.offset_x+self.width]
        cropped_pub_msg = self.bridge.cv2_to_imgmsg(cropped_img, "bgra8")
        cropped_pub_msg.header= header
        self.crop_pub.publish(cropped_pub_msg)

if __name__ == '__main__':
    raip = RectAddedImagePublisher()
    rospy.spin()
