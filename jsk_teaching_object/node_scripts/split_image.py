#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys

import rospy
from jsk_topic_tools import ConnectionBasedTransport
from sensor_msgs.msg import Image

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


class SplitImage(ConnectionBasedTransport):

    def __init__(self):
        super(SplitImage, self).__init__()
        self.vertical_parts = rospy.get_param('~vertical_parts', 1)
        self.horizontal_parts = rospy.get_param('~horizontal_parts', 1)
        self.pubs = []
        for v in range(self.vertical_parts):
            pubs = []
            for h in range(self.horizontal_parts):
                pubs.append(
                    self.advertise(
                        '~output/vertical{0:02}/horizontal{1:02}'.format(v, h),
                        Image,
                        queue_size=10))
            self.pubs.append(pubs)
        self.bridge = cv_bridge.CvBridge()

    def subscribe(self):
        self.sub = rospy.Subscriber('~input', Image, self._split_cb)

    def unsubscribe(self):
        self.sub.unregister()

    def _split_cb(self, msg):
        img = self.bridge.imgmsg_to_cv2(msg, desired_encoding='bgr8')
        height, width, _ = img.shape
        for v in range(self.vertical_parts):
            for h in range(self.horizontal_parts):
                v_pixels = float(height) / self.vertical_parts
                h_pixels = float(width) / self.horizontal_parts
                split_img = img[int(v*v_pixels):int((v+1)*v_pixels),
                                int(h*h_pixels):int((h+1)*h_pixels)]
                pub_msg = self.bridge.cv2_to_imgmsg(split_img, encoding='bgr8')
                pub_msg.header = msg.header
                self.pubs[v][h].publish(pub_msg)


if __name__ == '__main__':
    rospy.init_node('split_image')
    SplitImage()
    rospy.spin()
