import subprocess
import os
import argparse

# 引数の設定
def parse_args():
    parser = argparse.ArgumentParser(description="Run plot_senser_value.py on specified files.")
    parser.add_argument("directory", help="The directory containing the sensor data files.")
    return parser.parse_args()

def main():
    # 引数をパース
    args = parse_args()

    # オプション（-jを追加）
    option = "-j"
    # ファイルのリスト
    file_list = ["timstamped_cal_gas.csv", "timstamped_gas_v2_102b.csv", "timstamped_gas_v2_302b.csv", "timstamped_gas_v2_502b.csv", "timstamped_gas_v2_702b.csv", "timstamped_tgs_2600_analog.csv", "timstamped_tgs_2602_analog.csv", "timstamped_tgs_2603_analog.csv"]

    ## exec all_plot_senser_value.py
    python_script = "all_plot_senser_value.py"
    # コマンドを構築
    command = ["python", python_script, args.directory, option]
    try:
        print(f"Running command: {' '.join(command)}")
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error occurred: {e}")


    ## exec plot_senser_value.py
    python_script = "plot_senser_value.py"

    # ファイルリストに従ってコマンドを実行
    for file_name in file_list:
        # ファイルのフルパスを作成
        file_path = os.path.join(args.directory, file_name)

        # コマンドを構築
        command = ["python", python_script, file_path, option]

        # コマンドを実行
        try:
            print(f"Running command: {' '.join(command)}")
            subprocess.run(command, check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error occurred: {e}")

if __name__ == "__main__":
    main()
