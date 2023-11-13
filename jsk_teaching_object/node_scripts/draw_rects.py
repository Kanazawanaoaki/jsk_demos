#!/usr/bin/env python

import os
import os.path as osp
import sys

import dynamic_reconfigure.server
import message_filters
import numpy as np
import rospy
import sensor_msgs.msg
from jsk_recognition_msgs.msg import ClassificationResult, RectArray
from jsk_topic_tools import ConnectionBasedTransport, warn_no_remap
from PIL import Image, ImageDraw, ImageFont

from jsk_teaching_object.cfg import DrawRectsConfig

# OpenCV import for python3
if os.environ['ROS_PYTHON_VERSION'] == '3':
    import cv2
else:
    sys.path.remove('/opt/ros/{}/lib/python2.7/dist-packages'.format(os.getenv('ROS_DISTRO')))  # NOQA
    import cv2  # NOQA
    sys.path.append('/opt/ros/{}/lib/python2.7/dist-packages'.format(os.getenv('ROS_DISTRO')))  # NOQA


# cv_bridge_python3 import
if os.environ['ROS_PYTHON_VERSION'] == '3':
    import cv_bridge
else:
    ws_python3_paths = [p for p in sys.path if 'devel/lib/python3' in p]
    if len(ws_python3_paths) == 0:
        # search cv_bridge in workspace and append
        ws_python2_paths = [
            p for p in sys.path if 'devel/lib/python2.7' in p]
        for ws_python2_path in ws_python2_paths:
            ws_python3_path = ws_python2_path.replace('python2.7', 'python3')
            if os.path.exists(os.path.join(ws_python3_path, 'cv_bridge')):
                ws_python3_paths.append(ws_python3_path)
        if len(ws_python3_paths) == 0:
            opt_python3_path = '/opt/ros/{}/lib/python3/dist-packages'.format(
                os.getenv('ROS_DISTRO'))
            sys.path = [opt_python3_path] + sys.path
            import cv_bridge
            sys.path.remove(opt_python3_path)
        else:
            sys.path = [ws_python3_paths[0]] + sys.path
            import cv_bridge
            sys.path.remove(ws_python3_paths[0])
    else:
        import cv_bridge



# Taken from https://github.com/wkentaro/imgviz/blob/master/imgviz/label.py  # NOQA
def labelcolormap(N=256):
    """Label colormap.
    Parameters
    ----------
    N: int
        Number of labels (default: 256).

    Returns
    -------
    cmap: numpy.ndarray, (N, 3), numpy.uint8
        Label id to colormap.
    """

    def bitget(byteval, idx):
        shape = byteval.shape + (8,)
        return np.unpackbits(byteval).reshape(shape)[..., -1 - idx]

    i = np.arange(N, dtype=np.uint8)
    r = np.full_like(i, 0)
    g = np.full_like(i, 0)
    b = np.full_like(i, 0)

    i = np.repeat(i[:, None], 8, axis=1)
    i = np.right_shift(i, np.arange(0, 24, 3)).astype(np.uint8)
    j = np.arange(8)[::-1]
    r = np.bitwise_or.reduce(np.left_shift(bitget(i, 0), j), axis=1)
    g = np.bitwise_or.reduce(np.left_shift(bitget(i, 1), j), axis=1)
    b = np.bitwise_or.reduce(np.left_shift(bitget(i, 2), j), axis=1)

    cmap = np.stack((r, g, b), axis=1).astype(np.uint8)
    return cmap

def put_text_to_image(
        img, text, pos, font_path, font_size, color, background_color=None,
        offset_x=0, offset_y=0, loc='top'):
    """Put text to image using pillow.

    You can put text to an image including non-ASCII characters.

    Parameters
    ==========
    img : numpy.ndarray
        cv2 image. bgr order.
    text : str
        text information.
    pos : tuple(float)
        xy position of text.
    font_path : str
        path to font.
    font_size : int
        font size
    color : tuple(int)
        text color
    background_color : tuple(int) or None
        background color in text area. If this value is None, do nothing.
    offset_x : float
        x position offset.
    offset_y : float
        y position offset.
    loc : str
        location.
    """
    if sys.version_info < (3, 0):
        text = text.decode('utf-8')
    pil_font = ImageFont.truetype(font=font_path, size=font_size)
    dummy_draw = ImageDraw.Draw(Image.new("RGB", (0, 0)))
    (left, top, right, bottom) = dummy_draw.textbbox((0, 0), text, font=pil_font)
    text_w = right - left
    text_h = bottom - top
    text_bottom_offset = int(0.1 * text_h)
    x, y = pos
    if loc == 'top':
        offset_y = (text_h + text_bottom_offset) + offset_y
    elif loc == 'center':
        offset_y = offset_y
    else:
        raise NotImplementedError('loc {} not implemented.'.format(loc))
    x0 = x - offset_x
    y0 = y - offset_y
    img_h, img_w = img.shape[:2]
    # check outside of image.
    if not ((-text_w < x0 < img_w)
            and (-text_bottom_offset - text_h < y0 < img_h)):
        return img

    x1, y1 = max(x0, 0), max(y0, 0)
    x2 = min(x0+text_w, img_w)
    y2 = min(y0 + text_h + text_bottom_offset, img_h)
    x0 = int(x0)
    y0 = int(y0)
    x1 = int(x1)
    y1 = int(y1)
    x2 = int(x2)
    y2 = int(y2)

    # Create a black image of the same size as the text area.
    text_area = np.full(
        (text_h + text_bottom_offset, text_w, 3),
        (0, 0, 0), dtype=np.uint8)
    if background_color is not None:
        img[y1:y2, x1:x2] = np.array(background_color, dtype=np.uint8)
    # paste the original image on all or part of it.
    text_area[y1-y0:y2-y0, x1-x0:x2-x0] = img[y1:y2, x1:x2]

    # convert pil image to cv2 image.
    if not (text_area.shape[0] == 0 or text_area.shape[0] == 0):
        pil_img = Image.fromarray(text_area)
        draw = ImageDraw.Draw(pil_img)
        draw.text(xy=(0, 0), text=text, fill=color, font=pil_font)

        text_area = np.array(pil_img, dtype=np.uint8)
        img[y1:y2, x1:x2] = text_area[y1-y0:y2-y0, x1-x0:x2-x0]
    return img


class DrawRects(ConnectionBasedTransport):

    def __init__(self):
        super(DrawRects, self).__init__()

        self.colors = np.array(np.clip(
            labelcolormap() * 255, 0, 255), dtype=np.uint8)
        self.subs = []
        self.use_classification_result = DrawRectsConfig.defaults[
            'use_classification_result']
        self.approximate_sync = DrawRectsConfig.defaults['approximate_sync']
        self.queue_size = DrawRectsConfig.defaults['queue_size']
        self._srv_dynparam = dynamic_reconfigure.server.Server(
            DrawRectsConfig, self._config_callback)

        self.pub_viz = self.advertise(
            '~output', sensor_msgs.msg.Image, queue_size=1)

    def _config_callback(self, config, level):
        need_resubscribe = False
        if self.use_classification_result != config.use_classification_result \
           or self.approximate_sync != config.approximate_sync \
           or self.queue_size != config.queue_size:
            need_resubscribe = True

        self.approximate_sync = config.approximate_sync
        self.queue_size = config.queue_size
        self.use_classification_result = config.use_classification_result
        self.show_proba = config.show_proba
        self.rect_boldness = config.rect_boldness

        self.font_path = config.font_path
        if self.use_classification_result and not osp.exists(self.font_path):
            rospy.logwarn('Not valid font_path: {}'.format(self.font_path))
        self.label_size = int(np.ceil(config.label_size))
        self.label_boldness = config.label_boldness
        self.label_font = config.label_font
        self.label_margin_factor = config.label_margin_factor

        self.resolution_factor = config.resolution_factor
        self.interpolation_method = config.interpolation_method

        if need_resubscribe and self.is_subscribed():
            self.unsubscribe()
            self.subscribe()
        return config

    def subscribe(self):
        sub_image = message_filters.Subscriber('~input', sensor_msgs.msg.Image)
        sub_rects = message_filters.Subscriber('~input/rects', RectArray)
        warn_no_remap('~input', '~input/rects')

        subs = [sub_image, sub_rects]
        if self.use_classification_result:
            sub_class = message_filters.Subscriber(
                '~input/class', ClassificationResult)
            subs.append(sub_class)

        if self.approximate_sync:
            slop = rospy.get_param('~slop', 0.1)
            sync = message_filters.ApproximateTimeSynchronizer(
                subs,
                queue_size=self.queue_size, slop=slop)
            sync.registerCallback(self.draw_rects_callback)
        else:
            sync = message_filters.TimeSynchronizer(
                subs, queue_size=self.queue_size)
            sync.registerCallback(self.draw_rects_callback)
        self.subs = subs

    def unsubscribe(self):
        for sub in self.subs:
            sub.sub.unregister()

    def draw_rects_callback(self, img_msg, rects_msg, class_msg=None):
        bridge = cv_bridge.CvBridge()
        cv_img = bridge.imgmsg_to_cv2(img_msg, desired_encoding='bgr8')

        img = cv2.resize(cv_img, None,
                         fx=self.resolution_factor,
                         fy=self.resolution_factor,
                         interpolation=self.interpolation_method)
        for i, rect in enumerate(rects_msg.rects):
            if self.use_classification_result:
                label_idx = class_msg.labels[i]
            else:
                label_idx = i

            color = self.colors[label_idx % len(self.colors)]

            pt1 = (int(rect.x * self.resolution_factor),
                   int(rect.y * self.resolution_factor))
            pt2 = (int((rect.x + rect.width) * self.resolution_factor),
                   int((rect.y + rect.height) * self.resolution_factor))
            cv2.rectangle(img, pt1=pt1, pt2=pt2,
                          color=color.tolist(),
                          thickness=self.rect_boldness,
                          lineType=cv2.LINE_AA)
            if self.use_classification_result and osp.exists(self.font_path):
                text = class_msg.label_names[i]
                if self.show_proba and len(class_msg.label_proba) > i:
                    text += ' ({0:.2f})'.format(class_msg.label_proba[i])
                pos_x = int(rect.x * self.resolution_factor)
                pos_y = int(rect.y * self.resolution_factor)
                pos = (pos_x, pos_y)
                img = put_text_to_image(
                    img, text, pos, self.font_path,
                    self.label_size,
                    color=(255, 255, 255),
                    background_color=tuple(color),
                    offset_x=self.rect_boldness / 2.0)
        viz_msg = bridge.cv2_to_imgmsg(img, encoding='bgr8')
        viz_msg.header = img_msg.header
        self.pub_viz.publish(viz_msg)


if __name__ == '__main__':
    rospy.init_node('draw_rects')
    dr = DrawRects()
    rospy.spin()
