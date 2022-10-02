#! /usr/bin/env python
# coding: UTF-8
import rospy
import actionlib
from jsk_2022_09_fridge_pi.msg import *

# サーバー
class MyServer:
    # 初期化
    def __init__(self):
        # サーバーの生成
        self.server = actionlib.SimpleActionServer('add_two_ints',
            AddTwoIntsAction, self.listener_callback, False)

        # サーバーの開始
        self.server.start()

    # リクエストの受信時に呼ばれる
    def listener_callback(self, goal):
        # フィードバックの返信
        r = rospy.Rate(2)
        for i in range(10):
            feedback = AddTwoIntsFeedback(i * 0.1)
            self.server.publish_feedback(feedback)
            r.sleep()

        # レスポンスの返信
        result = AddTwoIntsResult(goal.a + goal.b)
        self.server.set_succeeded(result)

# メイン
def main():
    # ノードの初期化
    rospy.init_node("add_two_ints_server")

    # サーバーの開始
    server = MyServer()

    # ノード終了まで待機
    rospy.spin()

if __name__ == "__main__":
    main()
