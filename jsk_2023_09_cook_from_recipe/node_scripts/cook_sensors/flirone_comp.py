#!/usr/bin/env python
import rospy
import cv2
from sensor_msgs.msg import Image, CompressedImage
from cv_bridge import CvBridge

class ImageCompressor:
    def __init__(self):
        rospy.init_node("image_compressor", anonymous=True)
        self.bridge = CvBridge()
        
        # 入力: 非圧縮RGB画像
        self.image_sub = rospy.Subscriber("/flir/visible", Image, self.image_callback)

        # 出力: 圧縮RGB画像
        self.compressed_pub = rospy.Publisher("/flir/visible/compressed", CompressedImage, queue_size=1)

    def image_callback(self, msg):
        try:
            # Image メッセージを OpenCV 形式 (BGR) に変換
            cv_image = self.bridge.imgmsg_to_cv2(msg, desired_encoding="bgr8")

            # JPEG 圧縮
            success, encoded_image = cv2.imencode(".jpg", cv_image, [cv2.IMWRITE_JPEG_QUALITY, 90])
            if not success:
                rospy.logerr("Failed to encode image")
                return

            # CompressedImage メッセージを作成
            compressed_msg = CompressedImage()
            compressed_msg.header = msg.header
            compressed_msg.format = "jpeg"
            compressed_msg.data = encoded_image.tobytes()

            # パブリッシュ
            self.compressed_pub.publish(compressed_msg)

        except Exception as e:
            rospy.logerr("Error processing image: %s", str(e))

if __name__ == "__main__":
    try:
        ImageCompressor()
        rospy.spin()
    except rospy.ROSInterruptException:
        pass
