#!/usr/bin/env python
# -*- coding: utf-8 -*-

import subprocess

def list_controllers_with_state():
    # rosserviceを使用してコントローラ一覧と状態を取得
    result = subprocess.run(
        ['rosservice', 'call', '/pr2_controller_manager/list_controllers'],
        stdout=subprocess.PIPE
    )
    output = result.stdout.decode('utf-8')
    print(output)

    controllers = []
    states = []
    parse_mode = None

    for line in output.split('\n'):
        line = line.strip()
        if line.startswith('controllers:'):
            parse_mode = 'controllers'
        elif line.startswith('state:'):
            parse_mode = 'state'
        elif parse_mode == 'controllers' and line.startswith('-'):
            controllers.append(line.split(' ')[-1])
        elif parse_mode == 'state' and line.startswith('-'):
            states.append(line.split(' ')[-1])

    # コントローラと状態の辞書を作成
    controller_state_dict = dict(zip(controllers, states))
    return controller_state_dict

def load_controller(controller_name):
    # rosserviceでコントローラを読み込む
    subprocess.run(
        ['rosservice', 'call', '/pr2_controller_manager/load_controller', f"name: '{controller_name}'"]
    )

def check_and_load_controllers(controller_names):
    # 現在のコントローラリストと状態を取得
    controller_state_dict = list_controllers_with_state()

    # 各コントローラの確認と読み込みを行う
    for controller_name in controller_names:
        state = controller_state_dict.get(controller_name)
        if state:
            print(f"{controller_name} is already loaded with state: {state}")
        else:
            print(f"{controller_name} not found. Loading controller...")
            load_controller(controller_name)

if __name__ == "__main__":
    # 確認と読み込みを行うコントローラリスト
    controller_names = ['r_arm_controller', 'r_arm_controller_loose', 'l_arm_controller', 'l_arm_controller_loose']

    # 複数コントローラを一括で処理
    check_and_load_controllers(controller_names)
