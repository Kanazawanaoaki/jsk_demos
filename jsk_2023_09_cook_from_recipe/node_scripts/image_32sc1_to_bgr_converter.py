#!/usr/bin/env python

import rospy
from sensor_msgs.msg import Image
from cv_bridge import CvBridge, CvBridgeError
import cv2
import numpy as np

def image_callback(msg):
    try:
        bridge = CvBridge()
        # 32SC1形式のイメージをBGR8形式に変換
        cv_image = bridge.imgmsg_to_cv2(msg, desired_encoding="passthrough")

        # 32SC1を正規化して0から255の範囲に変換
        cv_image_normalized = cv2.normalize(cv_image, None, alpha=0, beta=255, norm_type=cv2.NORM_MINMAX, dtype=cv2.CV_8U)

        # グレースケールから3チャンネルに変換
        cv_image_bgr8 = cv2.cvtColor(cv_image_normalized, cv2.COLOR_GRAY2BGR)

        # 新しいヘッダーを作成
        new_header = msg.header

        # 変換したイメージを新しいトピックにパブリッシュ
        pub.publish(bridge.cv2_to_imgmsg(cv_image_bgr8, encoding="bgr8", header=new_header))
    except CvBridgeError as e:
        rospy.logerr(e)

if __name__ == '__main__':
    rospy.init_node('image_converter', anonymous=True)

    # 入力トピックと出力トピックの設定
    # input_topic = '/cutie_node/output/segmentation'
    # output_topic = '/cutie_node/output/segmentation_bgr'
    input_topic = '~input'
    output_topic = '~output'

    rospy.Subscriber(input_topic, Image, image_callback)
    pub = rospy.Publisher(output_topic, Image, queue_size=10)

    rospy.spin()
