#!/usr/bin/env python
# -*- coding: utf-8 -*-

import warnings

warnings.filterwarnings("ignore", category=DeprecationWarning)
import os
import re
import sys
from collections import defaultdict
from functools import lru_cache
from pathlib import Path
from threading import Lock

import cv2
import cv_bridge
import dynamic_reconfigure.server
import gdown
import numpy as np
import rospy
from cv_bridge import getCvType
from jsk_perception.cfg import ImagePublisherConfig
from PIL import Image as PIL_Image
from pybsc.image_utils import imread, squared_padding_image
from sensor_msgs.msg import CameraInfo, CompressedImage, Image
from std_msgs.msg import String

from jsk_teaching_object.put_text import put_text_to_image


@lru_cache(maxsize=None)
def cached_imread(img_path, image_width=500):
    return squared_padding_image(
        imread(img_path, 'bgra'), image_width)


def create_image_grid(root_image_path, image_caption, font_path, label_size, pos, encoding, cnt, grid_size=(5, 5), canvas_size=(2500, 2500), text_color=(255, 255, 255), background_color=(127, 127, 127, 255)):
    target_names = sorted(list(set([path.parent.name for path in sorted(root_image_path.glob('*/*.jpg'))])))
    canvas = np.zeros((*canvas_size, 4), dtype=np.uint8)
    grid_rows, grid_cols = grid_size
    cell_width, cell_height = canvas_size[0] // grid_cols, canvas_size[1] // grid_rows

    for i in range(grid_rows):
        for j in range(grid_cols):
            if i * grid_cols + j >= len(target_names):
                break
            target_name = target_names[i * grid_cols + j]
            filenames = sorted(list((root_image_path / target_name).glob('*.jpg')))
            cnt[target_name] = (cnt[target_name] + 1) % len(filenames)
            img = cached_imread(str(filenames[cnt[target_name]]), min(cell_width, cell_height))
            img = put_text_to_image(img, target_name, pos, font_path, label_size, color=text_color, background_color=background_color, offset_x=10)
            canvas[i * cell_height : (i + 1) * cell_height, j * cell_width : (j + 1) * cell_width] = img

    caption_image = np.zeros((label_size * 2, canvas_size[0], 4), dtype=np.uint8)
    caption_image = put_text_to_image(caption_image, image_caption, (10, label_size + label_size / 2.0), font_path, label_size, color=text_color, background_color=background_color, offset_x=10)
    canvas = np.concatenate([caption_image, canvas], axis=0)

    return canvas


class ShowImagePublisher(object):

    def __init__(self):
        self.lock = Lock()

        self.font_path = rospy.get_param(
            '~font_path',
            gdown.cached_download('https://github.com/googlefonts/noto-cjk/raw/main/Sans/OTF/Japanese/NotoSansCJKjp-Regular.otf'))
        self.label_size = 64
        self.text_pos = (10, self.label_size + self.label_size / 2.0)
        self.encoding = rospy.get_param('~encoding', 'bgra8')
        self.frame_id = rospy.get_param('~frame_id', 'camera')

        self.pub = rospy.Publisher('~output', Image, queue_size=1)
        self.pub_compressed = rospy.Publisher('{}/compressed'.format(rospy.resolve_name('~output')), CompressedImage, queue_size=1)

        rate = rospy.get_param('~rate', 1.)
        self.update_interval = rospy.get_param('~update_interval', 1.0)
        self.image_caption = rospy.get_param('~image_caption', 'Captured Image')
        self.root_image_path = rospy.get_param('~root_image_path')

        self.root_image_path = Path(self.root_image_path)
        self.cnt = defaultdict(int)

        self.cnt = defaultdict(int)
        with self.lock:
            if self.root_image_path is not None:
                canvas = create_image_grid(
                    self.root_image_path, self.image_caption, self.font_path,
                    self.label_size, self.text_pos, self.encoding,
                    self.cnt)
                self.imgmsg, self.compmsg = \
                    self.cv2_to_imgmsg(canvas, self.encoding)
        self.update_timer = rospy.Timer(rospy.Duration(self.update_interval), self.update_image,
                                        reset=True)
        self.publish_timer = rospy.Timer(rospy.Duration(1. / rate), self.publish,
                                         reset=True)

    def update_image(self, event):
        if self.root_image_path is None:
            return

        with self.lock:
            canvas = create_image_grid(
                self.root_image_path, self.image_caption, self.font_path,
                self.label_size, self.text_pos, self.encoding, self.cnt)
            self.imgmsg, self.compmsg = \
                self.cv2_to_imgmsg(canvas, self.encoding)

    def publish(self, event):
        if self.imgmsg is None:
            return
        now = rospy.Time.now()
        # setup ros message and publish
        with self.lock:
            self.imgmsg.header.stamp = \
                self.compmsg.header.stamp = now
            self.imgmsg.header.frame_id = \
                self.compmsg.header.frame_id = self.frame_id
        if self.pub.get_num_connections() > 0:
            self.pub.publish(self.imgmsg)
        if self.pub_compressed.get_num_connections() > 0:
            self.pub_compressed.publish(self.compmsg)

    def cv2_to_imgmsg(self, img, encoding):
        bridge = cv_bridge.CvBridge()
        # resolve encoding
        if getCvType(encoding) in [cv2.CV_8UC1, cv2.CV_16UC1, cv2.CV_32FC1]:
            # mono8
            if len(img.shape) == 3:
                if img.shape[2] == 4:
                    code = cv2.COLOR_BGRA2GRAY
                else:
                    code = cv2.COLOR_BGR2GRAY
                img = cv2.cvtColor(img, code)
            if getCvType(encoding) == cv2.CV_16UC1:
                # 16UC1
                img = img.astype(np.float32)
                img = img / 255 * (2 ** 16)
                img = img.astype(np.uint16)
            elif getCvType(encoding) == cv2.CV_32FC1:
                # 32FC1
                img = img.astype(np.float32)
                img /= 255
        elif getCvType(encoding) == cv2.CV_8UC3 and len(img.shape) == 3:
            # 8UC3
            # BGRA, BGR -> BGR
            img = img[:, :, :3]
            # BGR -> RGB
            if encoding in ('rgb8', 'rgb16'):
                img = img[:, :, ::-1]
        elif (getCvType(encoding) == cv2.CV_8UC4 and
                len(img.shape) == 3 and img.shape[2] == 4):
            # 8UC4
            if encoding in ('rgba8', 'rgba16'):
                # BGRA -> RGBA
                img = img[:, :, [2, 1, 0, 3]]
        else:
            rospy.logerr('unsupported encoding: {0}'.format(encoding))
            return
        compressed_msg = CompressedImage()
        compressed_msg.format = "jpeg"
        compressed_msg.data = np.array(
            cv2.imencode('.jpg', img)[1]).tostring()
        return bridge.cv2_to_imgmsg(img, encoding=encoding), compressed_msg


if __name__ == '__main__':
    rospy.init_node('show_image_publisher')
    ShowImagePublisher()
    rospy.spin()
