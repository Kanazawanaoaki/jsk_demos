import subprocess

def list_controllers():
    # rosserviceを使用してコントローラ一覧を取得
    result = subprocess.run(
        ['rosservice', 'call', '/pr2_controller_manager/list_controllers'],
        stdout=subprocess.PIPE
    )
    controllers_output = result.stdout.decode('utf-8')
    print(controllers_output)

    # コントローラ名を抽出
    controllers = []
    for line in controllers_output.split('\n'):
        if line.strip().startswith('-'):
            controllers.append(line.strip().split(' ')[-1])
    return controllers

def load_controller(controller_name):
    # rosserviceでコントローラを読み込む
    subprocess.run(
        ['rosservice', 'call', '/pr2_controller_manager/load_controller', f"name: '{controller_name}'"]
    )

def check_and_load_controllers(controller_names):
    # 現在のコントローラリストを取得
    controllers = list_controllers()

    # 各コントローラの確認と読み込みを行う
    for controller_name in controller_names:
        if controller_name not in controllers:
            print(f"{controller_name} not found. Loading controller...")
            load_controller(controller_name)
        else:
            print(f"{controller_name} is already loaded.")

if __name__ == "__main__":
    # 確認と読み込みを行うコントローラ
    check_and_load_controllers(['r_arm_controller_loose', 'l_arm_controller_loose'])
