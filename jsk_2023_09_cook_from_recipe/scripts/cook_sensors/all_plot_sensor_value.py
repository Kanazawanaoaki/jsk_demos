import argparse
import os
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime, timezone, timedelta

def convert_timestamp_to_japan_time(timestamp):
    utc_dt = datetime.fromtimestamp(timestamp, tz=timezone.utc)
    japan_time = utc_dt + timedelta(hours=9)
    return japan_time

def plot_all_sensor_data(input_dir, output_dir, japan_time):
    # ディレクトリ内のCSVファイルをすべて取得
    # csv_files = [f for f in os.listdir(input_dir) if f.endswith('.csv')]
    csv_files = sorted([f for f in os.listdir(input_dir) if f.endswith('.csv')])

    if not csv_files:
        print(f"No CSV files found in {input_dir}")
        return

    plt.figure(figsize=(10, 6))

    # 各ファイルのデータをプロット
    for csv_file in csv_files:
        file_path = os.path.join(input_dir, csv_file)
        df = pd.read_csv(file_path)

        # タイムスタンプを日本時間に変換
        if japan_time:
            df['Timestamp'] = df['Timestamp'].apply(convert_timestamp_to_japan_time)

        # プロットする
        timestamps = df['Timestamp'].values
        values = df['Value'].values
        plt.plot(timestamps, values, marker='o', linestyle='-', label=csv_file)

    plt.xlabel('Timestamp (JST)' if japan_time else 'Timestamp')
    plt.ylabel('Value')
    plt.title('All Sensor Data Plot')
    plt.legend()
    plt.grid(True)
    plt.xticks(rotation=45)
    plt.tight_layout()

    # 出力ファイル名の生成
    input_dir_name = os.path.basename(os.path.normpath(input_dir))
    output_file = os.path.join(output_dir, f"{input_dir_name}_all_plot.png")

    # 画像を保存
    plt.savefig(output_file)
    print(f"Plot saved to {output_file}")
    plt.show()
    plt.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Plot all sensor data from a directory of CSV files.')
    parser.add_argument('input_dir', type=str, help='Path to the directory containing CSV files with sensor data')
    parser.add_argument('--output_dir', '-o', default="../../datas/sensor_data_plots/", type=str, help='Path to the directory where the plot will be saved')
    parser.add_argument('--japan_time', '-j', action='store_true', help='Convert timestamps to Japan time (UTC+9)')

    args = parser.parse_args()
    plot_all_sensor_data(args.input_dir, args.output_dir, args.japan_time)
