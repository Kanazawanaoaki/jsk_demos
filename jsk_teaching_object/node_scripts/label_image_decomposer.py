#!/usr/bin/env python

import sys

import cv2
import matplotlib

matplotlib.use('Agg')  # NOQA
import cv_bridge
import dynamic_reconfigure.server
import matplotlib.cm
import message_filters
import numpy as np
import rospy
import scipy.ndimage
from jsk_perception.cfg import LabelImageDecomposerConfig
from jsk_topic_tools import ConnectionBasedTransport, warn_no_remap
from sensor_msgs.msg import Image


def bounding_rect_of_mask(img, mask):
    where = np.argwhere(mask)
    (y_start, x_start), (y_stop, x_stop) = where.min(0), where.max(0) + 1
    return img[y_start:y_stop, x_start:x_stop]


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


def get_text_color(color):
    if color[0] * 0.299 + color[1] * 0.587 + color[2] * 0.114 > 170:
        return (0, 0, 0)
    return (255, 255, 255)


def label2rgb(lbl, img=None, label_names=None, alpha=0.3, bg_label=0):
    if label_names is None:
        n_labels = lbl.max() + 1  # +1 for bg_label 0
    else:
        n_labels = len(label_names)
    cmap = labelcolormap(256)
    cmap = (cmap * 255).astype(np.uint8)
    bg_color, cmap = cmap[0], cmap[1:]  # bg_color is 0

    lbl_viz = np.zeros((lbl.shape[0], lbl.shape[1], 3), dtype=np.uint8)
    fg_mask = lbl != bg_label
    lbl_viz[fg_mask] = cmap[lbl[fg_mask] % 255]
    lbl_viz[~fg_mask] = bg_color

    if img is not None:
        if img.ndim == 3:
            img_gray = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
        else:
            assert img.ndim == 2
            img_gray = img
        img_gray = cv2.cvtColor(img_gray, cv2.COLOR_GRAY2RGB)
        lbl_viz = alpha * lbl_viz + (1 - alpha) * img_gray
        lbl_viz = lbl_viz.astype(np.uint8)

    if label_names is None:
        return lbl_viz

    np.random.seed(1234)
    labels = np.unique(lbl)
    labels = labels[labels != 0]
    for label in labels:
        mask = lbl == label
        mask = (mask * 255).astype(np.uint8)
        y, x = scipy.ndimage.center_of_mass(mask)
        y, x = map(int, [y, x])

        if lbl[y, x] != label:
            Y, X = np.where(mask)
            point_index = np.random.randint(0, len(Y))
            y, x = Y[point_index], X[point_index]

        text = label_names[label]
        font_face = cv2.FONT_HERSHEY_SIMPLEX
        font_scale = 0.7
        thickness = 2
        text_size, baseline = cv2.getTextSize(
            text, font_face, font_scale, thickness)

        color = get_text_color(lbl_viz[y, x])
        cv2.putText(lbl_viz, text,
                    (x - text_size[0] // 2, y),
                    font_face, font_scale, color, thickness)
    return lbl_viz


class LabelImageDecomposer(ConnectionBasedTransport):

    def __init__(self):
        super(LabelImageDecomposer, self).__init__()

        self._srv_dynparam = dynamic_reconfigure.server.Server(
            LabelImageDecomposerConfig, self._config_callback)

        self.pub_img = self.advertise('~output', Image, queue_size=5)
        self.pub_label_viz = self.advertise('~output/label_viz', Image,
                                            queue_size=5)
        self._bg_label = rospy.get_param('~bg_label', 0)  # ignored label
        self._only_label = rospy.get_param('~only_label', False)
        self._label_names = rospy.get_param('~label_names', None)
        # publish masks of fg/bg by decomposing each label
        self._publish_mask = rospy.get_param('~publish_mask', False)
        if self._publish_mask:
            self.pub_fg_mask = self.advertise('~output/fg_mask', Image,
                                              queue_size=5)
            self.pub_bg_mask = self.advertise('~output/bg_mask', Image,
                                              queue_size=5)
        # publish each region image. this can take time so optional.
        self._publish_tile = rospy.get_param('~publish_tile', False)
        rospy.loginfo('~publish_tile: {}'.format(self._publish_tile))
        if self._only_label and self._publish_tile:
            rospy.logerr('Can not publish tile image when ~only_label is true,'
                         ' so forcely set ~publish_tile to false.')
            self._publish_tile = False
        if self._publish_tile:
            self.pub_tile = self.advertise('~output/tile', Image, queue_size=5)

    def _config_callback(self, config, level):
        self._alpha = config.alpha
        return config

    def subscribe(self):
        self.sub_label = message_filters.Subscriber('~input/label', Image)
        if self._only_label:
            self.sub_label.registerCallback(self._apply)
            return
        self.sub_img = message_filters.Subscriber('~input', Image)
        warn_no_remap('~input', '~input/label')
        use_async = rospy.get_param('~approximate_sync', False)
        queue_size = rospy.get_param('~queue_size', 10)
        rospy.loginfo('~approximate_sync: {}, queue_size: {}'
                      .format(use_async, queue_size))
        if use_async:
            slop = rospy.get_param('~slop', 0.1)
            rospy.loginfo('~slop: {}'.format(slop))
            sync = message_filters.ApproximateTimeSynchronizer(
                [self.sub_label, self.sub_img],
                queue_size=queue_size, slop=slop)
            sync.registerCallback(self._apply)
            if self._publish_tile:
                sync.registerCallback(self._apply_tile)
        else:
            sync = message_filters.TimeSynchronizer(
                [self.sub_label, self.sub_img], queue_size=queue_size)
            sync.registerCallback(self._apply)
            if self._publish_tile:
                sync.registerCallback(self._apply_tile)

    def unsubscribe(self):
        self.sub_img.sub.unregister()
        self.sub_label.sub.unregister()

    def _apply(self, label_msg, img_msg=None):
        bridge = cv_bridge.CvBridge()
        label_img = bridge.imgmsg_to_cv2(label_msg)
        if img_msg:
            img = bridge.imgmsg_to_cv2(img_msg)
            # publish only valid label region
            applied = img.copy()
            applied[label_img == self._bg_label] = 0
            applied_msg = bridge.cv2_to_imgmsg(applied, encoding=img_msg.encoding)
            applied_msg.header = img_msg.header
            self.pub_img.publish(applied_msg)
            # publish visualized label
            if img_msg.encoding in {'16UC1', '32SC1'}:
                # do dynamic scaling to make it look nicely
                min_value, max_value = img.min(), img.max()
                img = (img - min_value) / (max_value - min_value) * 255
                img = img.astype(np.uint8)
                img = cv2.cvtColor(img, cv2.COLOR_GRAY2RGB)
        else:
            img = None

        label_viz = label2rgb(label_img, img, label_names=self._label_names,
                              alpha=self._alpha, bg_label=self._bg_label)
        label_viz_msg = bridge.cv2_to_imgmsg(label_viz, encoding='rgb8')
        label_viz_msg.header = label_msg.header
        self.pub_label_viz.publish(label_viz_msg)

        # publish mask
        if self._publish_mask:
            bg_mask = (label_img == 0)
            fg_mask = ~bg_mask
            bg_mask = (bg_mask * 255).astype(np.uint8)
            fg_mask = (fg_mask * 255).astype(np.uint8)
            fg_mask_msg = bridge.cv2_to_imgmsg(fg_mask, encoding='mono8')
            fg_mask_msg.header = label_msg.header
            bg_mask_msg = bridge.cv2_to_imgmsg(bg_mask, encoding='mono8')
            bg_mask_msg.header = label_msg.header
            self.pub_fg_mask.publish(fg_mask_msg)
            self.pub_bg_mask.publish(bg_mask_msg)

    def _apply_tile(self, label_msg, img_msg):
        bridge = cv_bridge.CvBridge()
        img = bridge.imgmsg_to_cv2(img_msg)
        label_img = bridge.imgmsg_to_cv2(label_msg)

        imgs = []
        labels = np.unique(label_img)
        for label in labels:
            if label == 0:
                # should be skipped 0, because
                # 0 is to label image as black region to mask image
                continue
            img_tmp = img.copy()
            mask = label_img == label
            img_tmp[~mask] = 0
            img_tmp = bounding_rect_of_mask(img_tmp, mask)
            imgs.append(img_tmp)
        tile_img = get_tile_image(imgs)
        tile_msg = bridge.cv2_to_imgmsg(tile_img, encoding='bgr8')
        tile_msg.header = img_msg.header
        self.pub_tile.publish(tile_msg)


if __name__ == '__main__':
    rospy.init_node('label_image_decomposer')
    label_image_decomposer = LabelImageDecomposer()
    rospy.spin()
