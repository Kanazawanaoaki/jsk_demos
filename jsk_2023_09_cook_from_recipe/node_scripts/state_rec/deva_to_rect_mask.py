#!/usr/bin/env python

import rospy
import cv2
from cv_bridge import CvBridge
from sensor_msgs.msg import Image
import numpy as np

# グローバル変数
bridge = CvBridge()
pub = None

def image_callback(msg):
    try:
        # ROSのイメージメッセージをOpenCV画像に変換（32SC1）
        cv_image = bridge.imgmsg_to_cv2(msg, "32SC1")
    except Exception as e:
        rospy.logerr("Error converting image: %s" % str(e))
        return

    # マスク画像のゼロ以外の領域を検出
    mask = cv_image != 0
    coords = np.column_stack(np.where(mask))  # マスクされた部分の座標を取得

    if coords.any():
        # バウンディングボックスの計算
        x_min, y_min = coords.min(axis=0)
        x_max, y_max = coords.max(axis=0)

        # 元の画像と同じサイズのゼロで埋められたマスク画像を作成
        new_mask_image = np.zeros_like(cv_image)

        # バウンディングボックス内を白（最大値）で埋める
        new_mask_image[x_min:x_max+1, y_min:y_max+1] = 2147483647  # 32ビット符号付き整数の最大値

        # マスク画像をBGRに変換（0~2147483647の範囲を0~255に正規化）
        norm_mask_image = cv2.normalize(new_mask_image, None, 0, 255, cv2.NORM_MINMAX).astype(np.uint8)
        bgr_mask_image = cv2.cvtColor(norm_mask_image, cv2.COLOR_GRAY2BGR)

        # 新しいBGRマスク画像をROSメッセージに変換してパブリッシュ
        new_mask_msg = bridge.cv2_to_imgmsg(bgr_mask_image, encoding="bgr8")
        new_mask_msg.header = msg.header  # 元のヘッダー情報を保持
        pub.publish(new_mask_msg)


        rospy.loginfo(f"Published new mask image with bounding box: [{x_min}, {y_min}] -> [{x_max}, {y_max}]")
    else:
        rospy.loginfo("No non-zero regions found in the mask image.")

def main():
    global pub

    # rospy.init_node('deva_to_rect_mask', anonymous=True)
    rospy.init_node('deva_to_rect_mask', anonymous=False)

    # マスク画像をサブスクライブ
    rospy.Subscriber("/deva_node/output/segmentation", Image, image_callback)

    # 新しいトピックにマスクされた画像をパブリッシュ
    pub = rospy.Publisher("~mask_image", Image, queue_size=10)

    rospy.spin()

if __name__ == '__main__':
    main()
