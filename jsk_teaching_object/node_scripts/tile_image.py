#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import division

import collections
import itertools
import math
import sys
from distutils.version import StrictVersion
from threading import Lock

import cv2
import cv_bridge
import message_filters
import numpy as np
import PIL
import pkg_resources
import rospy
from jsk_topic_tools import ConnectionBasedTransport
from sensor_msgs.msg import Image


def centerize(src, dst_shape, margin_color=None):
    """Centerize image for specified image size

    @param src: image to centerize
    @param dst_shape: image shape (height, width) or (height, width, channel)
    """
    if src.shape[:2] == dst_shape[:2]:
        return src
    centerized = np.zeros(dst_shape, dtype=src.dtype)
    if margin_color is not None:
        centerized[:, :] = margin_color
    pad_vertical, pad_horizontal = 0, 0
    h, w = src.shape[:2]
    dst_h, dst_w = dst_shape[:2]
    if h < dst_h:
        pad_vertical = (dst_h - h) // 2
    if w < dst_w:
        pad_horizontal = (dst_w - w) // 2
    centerized[pad_vertical:pad_vertical+h,
               pad_horizontal:pad_horizontal+w] = src
    return centerized

def _tile_images(imgs, tile_shape, concatenated_image, margin_color=None):
    """Concatenate images whose sizes are same.

    @param imgs: image list which should be concatenated
    @param tile_shape: shape for which images should be concatenated
    @param concatenated_image: returned image. if it is None, new image will be created.
    """
    x_num, y_num = tile_shape
    one_width = imgs[0].shape[1]
    one_height = imgs[0].shape[0]
    if concatenated_image is None:
        if imgs[0].ndim == 2:
            concatenated_image = np.zeros((one_height * y_num, one_width * x_num),
                                          dtype=np.uint8)
        elif imgs[0].ndim == 3:
            concatenated_image = np.zeros((one_height * y_num, one_width * x_num, 3),
                                          dtype=np.uint8)
        else:
            raise NotImplementedError
        if margin_color is not None:
            concatenated_image[:, :] = margin_color
    for y in range(y_num):
        for x in range(x_num):
            i = x + y * x_num
            if i >= len(imgs):
                pass
            else:
                concatenated_image[y*one_height:(y+1)*one_height,x*one_width:(x+1)*one_width,] = imgs[i]
    return concatenated_image


def get_tile_image(imgs, tile_shape=None, result_img=None, margin_color=None,
                   min_size=50):
    """Concatenate images whose sizes are different.

    @param imgs: image list which should be concatenated
    @param tile_shape: shape for which images should be concatenated
    @param result_img: numpy array to put result image
    """
    def get_tile_shape(img_num):
        x_num = 0
        y_num = int(math.sqrt(img_num))
        while x_num * y_num < img_num:
            x_num += 1
        return x_num, y_num

    if tile_shape is None:
        tile_shape = get_tile_shape(len(imgs))

    # get max tile size to which each image should be resized
    max_height, max_width = np.inf, np.inf
    for img in imgs:
        max_height = min([max_height, img.shape[0]])
        max_width = min([max_width, img.shape[1]])
    max_height = max(max_height, min_size)
    max_width = max(max_width, min_size)

    # resize and concatenate images
    for i, img in enumerate(imgs):
        h, w = img.shape[:2]
        h_scale, w_scale = max_height / h, max_width / w
        scale = min([h_scale, w_scale])
        h, w = int(scale * h), int(scale * w)
        img = cv2.resize(img, (w, h))
        if img.ndim == 2:
            img = centerize(img, (max_height, max_width),
                            margin_color=margin_color)
        elif img.ndim == 3:
            img = centerize(img, (max_height, max_width, 3),
                            margin_color=margin_color)
        else:
            raise NotImplementedError
        imgs[i] = img
    return _tile_images(imgs, tile_shape, result_img,
                        margin_color=margin_color)


def colorize_cluster_indices(image, cluster_indices, alpha=0.3, image_alpha=1):
    from skimage.color import gray2rgb, rgb2gray
    from skimage.color.colorlabel import DEFAULT_COLORS, color_dict
    from skimage.util import img_as_float
    image = img_as_float(rgb2gray(image))
    image = gray2rgb(image) * image_alpha + (1 - image_alpha)
    height, width = image.shape[:2]

    n_colors = len(DEFAULT_COLORS)
    indices_to_color = np.zeros((height * width, 3))
    for i, indices in enumerate(cluster_indices):
        color = color_dict[DEFAULT_COLORS[i % n_colors]]
        indices_to_color[indices] = color
    indices_to_color = indices_to_color.reshape((height, width, 3))
    result = indices_to_color * alpha + image * (1 - alpha)
    result = (result * 255).astype(np.uint8)
    return result


def draw_text_box(img, text, font_scale=0.8, thickness=2,
                  color=(0, 255, 0), fg_color=(0, 0, 0), loc='ltb'):
    font_face = cv2.FONT_HERSHEY_SIMPLEX
    size, baseline = cv2.getTextSize(text, font_face, font_scale, thickness)

    H, W = img.shape[:2]

    if loc == 'ltb':  # left + top + below
        # pt: (x, y)
        pt1 = (0, 0)
        pt2 = (size[0], size[1] + baseline)
        pt3 = (0, size[1])
    elif loc == 'rba':  # right + bottom + above
        pt1 = (W - size[0], H - size[1] - baseline)
        pt2 = (W, H)
        pt3 = (W - size[0], H - baseline)
    else:
        raise ValueError
    if color is not None:
        cv2.rectangle(img, pt1, pt2, color=color, thickness=-1)
    cv2.putText(img, text, pt3, font_face, font_scale, fg_color, thickness)


class TileImages(ConnectionBasedTransport):
    def __init__(self):
        super(TileImages, self).__init__()
        self.lock = Lock()
        self.input_topics = rospy.get_param('~input_topics', [])
        if not self.input_topics:
            rospy.logerr('need to specify input_topics')
            sys.exit(1)
        self._shape = rospy.get_param('~shape', None)
        if self._shape:
            if not (isinstance(self._shape, collections.Sequence) and
                    len(self._shape) == 2):
                rospy.logerr('~shape must be a list of 2 float values.')
                sys.exit(1)
            if (self._shape[0] * self._shape[1]) < len(self.input_topics):
                rospy.logerr('Tile size must be larger than # of input topics')
                sys.exit(1)
        self.cache_img = None
        self.draw_topic_name = rospy.get_param('~draw_topic_name', False)
        self.approximate_sync = rospy.get_param('~approximate_sync', True)
        self.no_sync = rospy.get_param('~no_sync', False)
        self.font_scale = rospy.get_param('~font_scale', 0.8)
        if (not self.no_sync and
            StrictVersion(pkg_resources.get_distribution('message_filters').version) < StrictVersion('1.11.4') and
            self.approximate_sync):
            rospy.logerr('hydro message_filters does not support approximate sync. Force to set ~approximate_sync=false')
            self.approximate_sync = False
        self.pub_img = self.advertise('~output', Image, queue_size=1)

    def subscribe(self):
        self.sub_img_list = []
        if self.no_sync:
            self.input_imgs = {}
            self.sub_img_list = [rospy.Subscriber(topic, Image, self.simple_callback(topic), queue_size=1) for topic in self.input_topics]
            rospy.Timer(rospy.Duration(0.1), self.timer_callback,
                        reset=True)
        else:
            queue_size = rospy.get_param('~queue_size', 10)
            slop = rospy.get_param('~slop', 1)
            for i, input_topic in enumerate(self.input_topics):
                sub_img = message_filters.Subscriber(input_topic, Image)
                self.sub_img_list.append(sub_img)
            if self.approximate_sync:
                sync = message_filters.ApproximateTimeSynchronizer(
                    self.sub_img_list, queue_size=queue_size, slop=slop)
                sync.registerCallback(self._apply)
            else:
                sync = message_filters.TimeSynchronizer(
                    self.sub_img_list, queue_size=queue_size)
                sync.registerCallback(self._apply)
    def unsubscribe(self):
        for sub in self.sub_img_list:
            sub.sub.unregister()
    def timer_callback(self, event):
        with self.lock:
            imgs = [self.input_imgs[topic] for topic in self.input_topics
                    if topic in self.input_imgs]
            self._append_images(imgs)
    def simple_callback(self, target_topic):
        def callback(msg):
            with self.lock:
                bridge = cv_bridge.CvBridge()
                img = bridge.imgmsg_to_cv2(msg, desired_encoding='bgr8')
                self.input_imgs[target_topic] = img
                if self.draw_topic_name:
                    draw_text_box(img, rospy.resolve_name(target_topic),
                                  font_scale=self.font_scale)
        return callback
    def _append_images(self, imgs):
        if not imgs:
            return
        # convert tile shape: (Y, X) -> (X, Y)
        # if None, shape is automatically decided to be square AMAP.
        shape_xy = self._shape[::-1] if self._shape else None
        if self.cache_img is None:
            out_bgr = get_tile_image(
                imgs, tile_shape=shape_xy)
            self.cache_img = out_bgr
        else:
            try:
                out_bgr = get_tile_image(
                    imgs, tile_shape=shape_xy, result_img=self.cache_img)
            except ValueError:  # cache miss
                out_bgr = get_tile_image(
                    imgs, tile_shape=shape_xy)
                self.cache_img = out_bgr
        bridge = cv_bridge.CvBridge()
        imgmsg = bridge.cv2_to_imgmsg(out_bgr, encoding='bgr8')
        imgmsg.header.stamp = rospy.Time.now()
        self.pub_img.publish(imgmsg)
    def _apply(self, *msgs):
        bridge = cv_bridge.CvBridge()
        imgs = []
        for msg, topic in zip(msgs, self.input_topics):
            img = bridge.imgmsg_to_cv2(msg, desired_encoding='bgr8')
            if self.draw_topic_name:
                draw_text_box(img, rospy.resolve_name(topic),
                              font_scale=self.font_scale)
            imgs.append(img)
        self._append_images(imgs)


if __name__ == '__main__':
    rospy.init_node('tile_image')
    tile_image = TileImages()
    rospy.spin()
