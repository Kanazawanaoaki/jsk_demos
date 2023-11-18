#!/usr/bin/env python
import rospy
from std_msgs.msg import Float32MultiArray, Float32
from std_srvs.srv import Empty

class MovingAverageNode:
    def __init__(self):
        rospy.init_node('moving_average_node', anonymous=True)

        self.subscriber = rospy.Subscriber('/pr2_cook_imagebind/recog_result', Float32MultiArray, self.callback)
        self.publisher = rospy.Publisher('/pr2_cook_imagebind/recog_result/moving_average', Float32, queue_size=10)

        self.data_buffer = []
        self.window_size = 30
        self.collect_data = False

        # サービスの設定
        self.start_service = rospy.Service('start_moving_average', Empty, self.start_collecting)
        self.stop_service = rospy.Service('stop_moving_average', Empty, self.stop_collecting)

    def callback(self, data):
        if self.collect_data:
            self.data_buffer.append(data)

            if len(self.data_buffer) >= self.window_size:
                # 移動平均を計算
                moving_average = self.calculate_moving_average()

                # パブリッシュ
                self.publish_data(moving_average)

                # 一番古いデータを削除
                self.data_buffer.pop(0)

    def calculate_moving_average(self):
        total = sum([value.data[0] for value in self.data_buffer])
        return total / len(self.data_buffer)

    def publish_data(self, moving_average):
        output_msg = Float32(data=moving_average)
        self.publisher.publish(output_msg)

    def start_collecting(self, req):
        rospy.loginfo("Start collecting data.")
        self.collect_data = True
        return {}

    def stop_collecting(self, req):
        rospy.loginfo("Stop collecting data.")
        self.collect_data = False
        # データバッファをリセット
        self.data_buffer = []
        return {}

    def run(self):
        rospy.spin()

if __name__ == '__main__':
    node = MovingAverageNode()
    node.run()
