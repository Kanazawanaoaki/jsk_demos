#!/usr/bin/env python
import argparse
import rospy
from pr2_mechanism_msgs.srv import SwitchController

def switch_manequine_controller(arm, state):
    # コントローラのリストを準備
    start_controllers = []
    stop_controllers = []

    if arm in ['larm', 'both']:
        l_start_controller = 'l_arm_controller_loose' if state == 'on' else 'l_arm_controller'
        l_stop_controller = 'l_arm_controller' if state == 'on' else 'l_arm_controller_loose'
        start_controllers.append(l_start_controller)
        stop_controllers.append(l_stop_controller)

    if arm in ['rarm', 'both']:
        r_start_controller = 'r_arm_controller_loose' if state == 'on' else 'r_arm_controller'
        r_stop_controller = 'r_arm_controller' if state == 'on' else 'r_arm_controller_loose'
        start_controllers.append(r_start_controller)
        stop_controllers.append(r_stop_controller)

    # サービスが準備されるまで待機
    rospy.wait_for_service('/pr2_controller_manager/switch_controller')

    try:
        # サービスプロキシを作成して呼び出し
        switch_controller_service = rospy.ServiceProxy('/pr2_controller_manager/switch_controller', SwitchController)
        response = switch_controller_service(start_controllers, stop_controllers, 0)

        if response.ok:
            rospy.loginfo(f"Successfully switched {arm} to {state} mode.")
        else:
            rospy.logerr(f"Failed to switch {arm} to {state} mode.")

    except rospy.ServiceException as e:
        rospy.logerr(f"Service call failed: {e}")

if __name__ == "__main__":
    # ノードの初期化
    rospy.init_node('arm_manequine_controller_switcher', anonymous=True)

    # 引数のパーサーをセットアップ
    parser = argparse.ArgumentParser(description='Switch arm controllers for manequine mode in PR2.')
    parser.add_argument('arm', choices=['larm', 'rarm', 'both'], help='Specify which arm to control (larm, rarm, or both).')
    parser.add_argument('state', choices=['on', 'off'], help='Specify the state to switch the controller to (on for mannequin mode or off for normal mode).')

    args = parser.parse_args()

    # コントローラの切り替えを実行
    switch_manequine_controller(args.arm, args.state)
