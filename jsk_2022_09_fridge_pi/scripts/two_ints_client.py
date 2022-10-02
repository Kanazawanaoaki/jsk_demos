#! /usr/bin/env python
# coding: UTF-8
import rospy
import actionlib
from jsk_2022_09_fridge_pi.msg import *

# フィードバックの受信時に呼ばれる
def feedback_callback(feedback):
    print "feedback :", feedback.rate

# メイン
def main():
    # ノードの初期化
    rospy.init_node("add_two_ints_client")

    # クライアントの生成
    client = actionlib.SimpleActionClient("add_two_ints", AddTwoIntsAction)

    # サーバー接続まで待機
    client.wait_for_server()

    # メッセージの生成
    a = 1
    b = 2
    goal = AddTwoIntsGoal(a, b)

    # リクエストの送信
    client.send_goal(goal, feedback_cb=feedback_callback)

    # レスポンスの受信
    client.wait_for_result()
    result = client.get_result()
    print "%s + %s = %s"%(a, b, result.sum)

if __name__ == "__main__":
   main()
