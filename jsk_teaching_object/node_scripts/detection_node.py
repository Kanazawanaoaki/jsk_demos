#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import print_function

from threading import Lock

import actionlib
from cv_bridge import CvBridge
from dynamic_reconfigure.server import Server
from jsk_perception.cfg import SSDObjectDetectorConfig as Config
from jsk_recognition_msgs.msg import ClassificationResult
from jsk_recognition_msgs.msg import ClusterPointIndices
from jsk_recognition_msgs.msg import Label
from jsk_recognition_msgs.msg import LabelArray
from jsk_recognition_msgs.msg import Rect
from jsk_recognition_msgs.msg import RectArray
from jsk_topic_tools import ConnectionBasedTransport
import numpy as np
from pcl_msgs.msg import PointIndices
import rospy
from sensor_msgs.msg import Image
import torch

from jsk_teaching_object.inference_utils import inference_img
from jsk_teaching_object.inference_utils import visualize_inference
from jsk_teaching_object.msg import UpdateModelAction
from jsk_teaching_object.msg import UpdateModelResult
from jsk_teaching_object.rpn import get_model_rpn


class ObjectDetectorNode(ConnectionBasedTransport):

    def __init__(self):
        super(ObjectDetectorNode, self).__init__()
        self.classifier_name = rospy.get_param(
            "~classifier_name", rospy.get_name())

        self.cv_bridge = CvBridge()

        self.lock = Lock()

        model_path = rospy.get_param('~model_path')
        class_name_path = rospy.get_param('~class_name_path')
        self.load_model(model_path, class_name_path)

        # dynamic reconfigure
        self.srv = Server(Config, self.config_callback)

        # advertise
        self.pub_labels = self.advertise("~output/labels", LabelArray,
                                         queue_size=1)
        self.pub_indices = self.advertise(
            "~output/cluster_indices", ClusterPointIndices,
            queue_size=1)
        self.pub_rects = self.advertise("~output/rects", RectArray,
                                        queue_size=1)
        self.pub_class = self.advertise("~output/class", ClassificationResult,
                                        queue_size=1)
        self.pub_image = self.advertise("~output/image", Image,
                                        queue_size=1)

        self.update_model_server = actionlib.SimpleActionServer(
            '~update_model',
            UpdateModelAction,
            execute_cb=self.update_model_action,
            auto_start=True)
        rospy.loginfo('update model action started.')

    def update_model_action(self, goal):
        self.load_model(goal.model_path, goal.class_name_path)
        self.update_model_server.set_succeeded(UpdateModelResult())

    def load_model(self, model_path, class_name_path):
        self.lock.acquire()
        class_names = []
        with open(class_name_path, 'r') as f:
            for line in f.readlines():
                class_names.append(line.strip())
        self.class_names = class_names
        rospy.loginfo("Loaded {} labels. {}".format(
            len(self.class_names),
            self.class_names))
        num_classes = len(class_names)

        rospy.loginfo('Loading model {}'.format(model_path))
        model = get_model_rpn(num_classes, model_path)
        device = torch.device('cuda') \
            if torch.cuda.is_available() else torch.device('cpu')
        model.to(device)
        model.eval()
        self.model = model
        self.device = device

        self.lock.release()

    def subscribe(self):
        self.sub_image = rospy.Subscriber(
            '~input',
            Image, self.image_cb,
            queue_size=1, buff_size=2**26)

    def unsubscribe(self):
        self.sub_image.unregister()

    @property
    def visualize(self):
        return self.pub_image.get_num_connections() > 0

    def config_callback(self, config, level):
        self.nms_thresh = config.nms_thresh
        self.score_thresh = config.score_thresh
        self.profiling = config.profiling
        return config

    def image_cb(self, msg):
        with self.lock:
            try:
                # transform image to RGB, float, CHW
                img = self.cv_bridge.imgmsg_to_cv2(
                    msg, desired_encoding="rgb8")
            except Exception as e:
                rospy.logerr("Failed to convert image: %s" % str(e))
                return

            out_result = inference_img(img.copy(),
                                       self.model, self.device,
                                       self.class_names,
                                       input_size=300,
                                       window_size=200,
                                       enable_tile=False)
            bboxes = out_result['boxes']
            labels = out_result['labels']
            scores = out_result['scores']
            label_names = out_result['label_names']
            valid_indices = scores > self.score_thresh
            scores = scores[valid_indices]
            labels = labels[valid_indices]
            label_names = label_names[valid_indices]
            if len(bboxes) > 0:
                bboxes = bboxes[valid_indices]

            valid_indices = label_names != 'others'
            scores = scores[valid_indices]
            labels = labels[valid_indices]
            label_names = label_names[valid_indices]
            if len(bboxes) > 0:
                bboxes = bboxes[valid_indices]

            labels_msg = LabelArray(header=msg.header)
            for l in labels:
                l_name = self.class_names[l]
                labels_msg.labels.append(Label(id=l, name=l_name))

            cluster_indices_msg = ClusterPointIndices(header=msg.header)
            H, W, _ = img.shape
            for bbox in bboxes:
                xmin = max(0, int(np.floor(bbox[0])))
                ymin = max(0, int(np.floor(bbox[1])))
                xmax = min(W, int(np.ceil(bbox[2])))
                ymax = min(H, int(np.ceil(bbox[3])))
                indices = [list(range(W * y + xmin, W * y + xmax))
                           for y in range(ymin, ymax)]
                indices = np.array(indices, dtype=np.int32).flatten()
                indices_msg = PointIndices(header=msg.header, indices=indices)
                cluster_indices_msg.cluster_indices.append(indices_msg)

            rect_msg = RectArray(header=msg.header)
            for bbox in bboxes:
                rect = Rect(x=int(bbox[0]), y=int(bbox[1]),
                            width=int(bbox[2] - bbox[0]),
                            height=int(bbox[3] - bbox[1]))
                rect_msg.rects.append(rect)

            cls_msg = ClassificationResult(
                header=msg.header,
                classifier=self.classifier_name,
                target_names=self.class_names,
                labels=labels,
                label_names=[self.class_names[l] for l in labels],
                label_proba=scores,
            )

            self.pub_labels.publish(labels_msg)
            self.pub_indices.publish(cluster_indices_msg)
            self.pub_rects.publish(rect_msg)
            self.pub_class.publish(cls_msg)

            if self.visualize:
                viz_img = visualize_inference(img, out_result,
                                              score_thresh=self.score_thresh,
                                              nms_thresh=self.nms_thresh,
                                              ignore_labels=['others',])
                try:
                    out_msg = self.cv_bridge.cv2_to_imgmsg(viz_img, "rgb8")
                except Exception as e:
                    rospy.logerr("Failed to convert bbox image: %s" % str(e))
                    return
                out_msg.header = msg.header
                self.pub_image.publish(out_msg)


if __name__ == '__main__':
    rospy.init_node("object_detector_node")
    ssd = ObjectDetectorNode()
    rospy.spin()
