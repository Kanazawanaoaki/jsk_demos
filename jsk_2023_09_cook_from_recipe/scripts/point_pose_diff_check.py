# import rospy
# from posedetection_msgs.msg import ObjectDetection

# def callback(msg):
#     # ここに座標のぶれを計算するコードを追加
#     x = msg.objects[0].pose.position.x
#     y = msg.objects[0].pose.position.y
#     z = msg.objects[0].pose.position.z
#     print(f"Received ObjectDetection message: x={x}, y={y}, z={z}")

# def subscribe_to_object_detection_topic():
#     rospy.init_node('object_detection_subscriber', anonymous=True)
#     rospy.Subscriber('/point_pose_kitchen/ObjectDetection', ObjectDetection, callback)
#     rospy.spin()

# if __name__ == '__main__':
#     subscribe_to_object_detection_topic()

import rospy
from posedetection_msgs.msg import ObjectDetection
import numpy as np

class PoseVarianceCalculator:
    def __init__(self, num_subscriptions=10):
        self.num_subscriptions = num_subscriptions
        self.current_subscription_count = 0
        self.all_messages = []

        # ROSノードの初期化
        rospy.init_node('pose_variance_calculator', anonymous=True)

        # サブスクライバの設定
        # rospy.Subscriber('/point_pose_kitchen/ObjectDetection', ObjectDetection, self.callback)
        rospy.Subscriber('/point_pose_sink/ObjectDetection', ObjectDetection, self.callback)
        # rospy.Subscriber('/point_pose_kitchen/ObjectDetection', ObjectDetection, self.callback)

    def callback(self, msg):
        # メッセージから座標を取得
        x = msg.objects[0].pose.position.x
        y = msg.objects[0].pose.position.y
        z = msg.objects[0].pose.position.z

        # メッセージを保存
        self.all_messages.append([x, y, z])

        # サブスクライプション回数を更新
        self.current_subscription_count += 1

        # 指定回数サブスクライブしたら座標のぶれを計算
        if self.current_subscription_count == self.num_subscriptions:
            self.calculate_and_print_variance()
            rospy.signal_shutdown("Finished processing")

    def calculate_and_print_variance(self):
        # リストをNumPy配列に変換
        poses_array = np.array(self.all_messages)

        # 各座標軸ごとのぶれを計算
        x_variance = np.var(poses_array[:, 0])
        y_variance = np.var(poses_array[:, 1])
        z_variance = np.var(poses_array[:, 2])

        # 結果を表示
        print(f"X軸のぶれ: {x_variance}")
        print(f"Y軸のぶれ: {y_variance}")
        print(f"Z軸のぶれ: {z_variance}")

    def run(self):
        # ROSスピン開始
        rospy.spin()

if __name__ == '__main__':
    pose_calculator = PoseVarianceCalculator()
    pose_calculator.run()
