#!/usr/bin/env python

import rospy
import cv2
from cv_bridge import CvBridge
from sensor_msgs.msg import Image
from datetime import datetime
import os
from std_srvs.srv import Empty, EmptyResponse

class PeriodicImageSaver:
    def __init__(self):
        # ノードの初期化
        rospy.init_node('periodic_image_saver', anonymous=True)

        # rosparamから保存先ディレクトリを取得
        self.base_save_path = rospy.get_param('~save_path', '/tmp/images')
        self.current_save_path = None

        # CvBridgeの初期化
        self.bridge = CvBridge()

        # 画像トピックのサブスクライバの設定
        image_topic = rospy.get_param('~input', '/camera_remote/rgb/image_raw')
        self.image_sub = rospy.Subscriber(image_topic, Image, self.callback)

        # 定期的に保存するためのタイマーの設定
        self.time_duration = 60 # 60=1min.
        self.timer = rospy.Timer(rospy.Duration(self.time_duration), self.save_image_periodically)

        # 保存する画像データを保持する変数
        self.latest_image = None

        # サービスの設定
        self.start_service = rospy.Service('~start_saving', Empty, self.start_saving)
        self.stop_service = rospy.Service('~stop_saving', Empty, self.stop_saving)

        self.saving_enabled = False

    def callback(self, msg):
        # 画像メッセージをOpenCV形式に変換
        self.latest_image = self.bridge.imgmsg_to_cv2(msg, desired_encoding='bgr8')

    def save_image_periodically(self, event):
        if self.saving_enabled and self.latest_image is not None and self.current_save_path:
            # 現在のUNIXタイムスタンプを取得
            unix_timestamp = int(datetime.utcnow().timestamp())
            japan_time_str = datetime.now().strftime('%Y%m%d_%H%M%S')

            # ファイル名にタイムスタンプと日本時間を含める
            filename = os.path.join(self.current_save_path, f'image_{unix_timestamp}_{japan_time_str}.png')

            # 画像をファイルに保存
            cv2.imwrite(filename, self.latest_image)
            rospy.loginfo(f'Saved image to {filename}')
        elif not self.saving_enabled:
            rospy.loginfo('Saving is disabled')

    def start_saving(self, req):
        if not self.saving_enabled:
            # 現在の時刻を取得してディレクトリを作成
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            self.current_save_path = os.path.join(self.base_save_path, f'session_{timestamp}')
            os.makedirs(self.current_save_path, exist_ok=True)
            self.saving_enabled = True
            rospy.loginfo(f'Saving started. Directory created: {self.current_save_path}')
        else:
            rospy.logwarn('Saving is already enabled')
        return EmptyResponse()

    def stop_saving(self, req):
        if self.saving_enabled:
            self.saving_enabled = False
            rospy.loginfo('Saving stopped')
        else:
            rospy.logwarn('Saving is already disabled')
        return EmptyResponse()

if __name__ == '__main__':
    try:
        periodic_image_saver = PeriodicImageSaver()
        rospy.spin()
    except rospy.ROSInterruptException:
        pass
