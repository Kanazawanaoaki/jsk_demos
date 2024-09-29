#!/usr/bin/env python

import rospy
import cv2
from cv_bridge import CvBridge
from sensor_msgs.msg import Image
import numpy as np
import os

def image_callback(msg):
    # CvBridgeを使ってROSメッセージからOpenCV形式に変換
    bridge = CvBridge()
    try:
        # 32SC1のエンコーディングでマスク画像として変換
        cv_image = bridge.imgmsg_to_cv2(msg, "32SC1")
    except Exception as e:
        rospy.logerr("Error converting image: %s" % str(e))
        return

    # ファイル名にタイムスタンプを使用
    timestamp = msg.header.stamp.secs + msg.header.stamp.nsecs / 1e9
    file_name = "mask_image_{:.6f}.png".format(timestamp)

    # ファイルを保存するディレクトリのパス
    save_dir = "/tmp/"
    if not os.path.exists(save_dir):
        os.makedirs(save_dir)

    # フルパスを作成
    file_path = os.path.join(save_dir, file_name)

    # 画像をファイルに保存
    # 32SC1形式を保存するため、データ型を適切に変換（8ビットにスケーリング）
    cv_image_normalized = cv2.normalize(cv_image, None, 0, 255, cv2.NORM_MINMAX, dtype=cv2.CV_8U)
    cv2.imwrite(file_path, cv_image_normalized)

    rospy.loginfo("Saved image: %s" % file_path)

def main():
    rospy.init_node('mask_image_saver', anonymous=True)

    # トピックのサブスクライブ
    rospy.Subscriber("/deva_node/output/segmentation", Image, image_callback)

    rospy.spin()

if __name__ == '__main__':
    main()
