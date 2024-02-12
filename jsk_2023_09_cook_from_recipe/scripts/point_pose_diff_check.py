import rospy
from posedetection_msgs.msg import ObjectDetection
import numpy as np
import tf
import quaternion

def convert_to_signed_difference(value):
    if value < 0:
        return 180 + value
    else:
        return value - 180

def calculate_difference(arr):
    arr = np.array(arr)
    max_value = np.max(arr)
    min_value = np.min(arr)

    difference = max_value - min_value

    return difference

class PoseVarianceCalculator:
    def __init__(self, num_subscriptions=10):
        self.num_subscriptions = num_subscriptions
        self.current_subscription_count = 0
        self.all_messages = []
        self.raw_msgs = []

        # ROSノードの初期化
        rospy.init_node('pose_variance_calculator', anonymous=True)

        # サブスクライバの設定
        # rospy.Subscriber('/point_pose_kitchen/ObjectDetection', ObjectDetection, self.callback)
        # rospy.Subscriber('/point_pose_sink/ObjectDetection', ObjectDetection, self.callback)
        rospy.Subscriber('/point_pose_stove/ObjectDetection', ObjectDetection, self.callback)

    def callback(self, msg):
        # メッセージから座標を取得
        x = msg.objects[0].pose.position.x
        y = msg.objects[0].pose.position.y
        z = msg.objects[0].pose.position.z

        # メッセージを保存
        self.all_messages.append([x, y, z,])

        self.raw_msgs.append(msg)

        # サブスクライプション回数を更新
        self.current_subscription_count += 1

        # 指定回数サブスクライブしたら座標のぶれを計算
        if self.current_subscription_count == self.num_subscriptions:
            self.calculate_and_print_variance()
            rospy.signal_shutdown("Finished processing")

    # def calculate_and_print_variance(self):
    #     # リストをNumPy配列に変換
    #     poses_array = np.array(self.all_messages)

    #     # 各座標軸ごとのぶれを計算
    #     x_variance = np.var(poses_array[:, 0])
    #     y_variance = np.var(poses_array[:, 1])
    #     z_variance = np.var(poses_array[:, 2])

    #     # 結果を表示
    #     print(f"X軸のぶれ: {x_variance}")
    #     print(f"Y軸のぶれ: {y_variance}")
    #     print(f"Z軸のぶれ: {z_variance}")
    def calculate_and_print_variance(self):
        # リストをNumPy配列に変換
        poses_array = np.array(self.all_messages)

        # 各座標軸ごとのぶれを計算
        x_variance = np.var(poses_array[:, 0])
        y_variance = np.var(poses_array[:, 1])
        z_variance = np.var(poses_array[:, 2])
        x_diff = calculate_difference(poses_array[:, 0])
        y_diff = calculate_difference(poses_array[:, 1])
        z_diff = calculate_difference(poses_array[:, 2])

        print("x軸周りの回転のズレ")
        x_angles = []
        for msg in self.raw_msgs:
            # クオータニオンの作成
            # quat = Quaternion(msg.objects[0].pose.orientation.w, msg.objects[0].pose.orientation.x, msg.objects[0].pose.orientation.y, msg.objects[0].pose.orientation.xz)
            # quat = np.quaternion(msg.objects[0].pose.orientation.w, msg.objects[0].pose.orientation.x, msg.objects[0].pose.orientation.y, msg.objects[0].pose.orientation.z)

            # クオータニオンの作成
            quat = quaternion.quaternion(msg.objects[0].pose.orientation.w, msg.objects[0].pose.orientation.x, msg.objects[0].pose.orientation.y, msg.objects[0].pose.orientation.z)

            # クオータニオンを回転行列に変換
            rotation_matrix = quaternion.as_rotation_matrix(quat)

            # 回転行列からx軸周りの回転角度を抽出
            pitch_rad = -np.arctan2(rotation_matrix[2, 0], rotation_matrix[2, 2])

            # ラジアンから度に変換
            pitch_deg = np.degrees(pitch_rad)
            print(pitch_deg, convert_to_signed_difference(pitch_deg))
            x_angles.append(convert_to_signed_difference(pitch_deg))

        x_rot_variance = np.var(x_angles)
        x_rot_diff = calculate_difference(x_angles)
        # 結果を表示
        print(f"X軸の分散: {x_variance}")
        print(f"Y軸の分散: {y_variance}")
        print(f"Z軸の分散: {z_variance}")
        print(f"X軸周りの分散: {x_rot_variance}")
        print(f"X軸のぶれ: {x_diff}")
        print(f"Y軸のぶれ: {y_diff}")
        print(f"Z軸のぶれ: {z_diff}")
        print(f"X軸周りのぶれ: {x_rot_diff}")

    def run(self):
        # ROSスピン開始
        rospy.spin()

if __name__ == '__main__':
    pose_calculator = PoseVarianceCalculator()
    pose_calculator.run()
