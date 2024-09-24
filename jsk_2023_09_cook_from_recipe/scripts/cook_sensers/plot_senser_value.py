import argparse
import os
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime, timezone, timedelta

def convert_timestamp_to_japan_time(timestamp):
    utc_dt = datetime.fromtimestamp(timestamp, tz=timezone.utc)
    japan_time = utc_dt + timedelta(hours=9)
    return japan_time

def plot_sensor_data(file_path, output_dir, japan_time):
    # CSVファイルを読み込む
    df = pd.read_csv(file_path)

    if japan_time:
        # タイムスタンプを日本時間に変換
        df['Timestamp'] = df['Timestamp'].apply(convert_timestamp_to_japan_time)
        x_label = 'Timestamp (JST)'
    else:
        x_label = 'Timestamp'

    # NumPy配列に変換する例（この例では特に変換は不要ですが、エラー回避のための操作です）
    timestamps = df['Timestamp'].values
    values = df['Value'].values

    # プロット
    plt.figure(figsize=(10, 6))
    plt.plot(timestamps, values, marker='o', linestyle='-')
    plt.xlabel(x_label)
    plt.ylabel('Value')
    plt.title('Sensor Data Plot')
    plt.grid(True)
    plt.xticks(rotation=45)
    plt.tight_layout()

    # 出力ファイル名の生成
    # 最後の2つのディレクトリ名とファイル名を取り出す
    path_parts = file_path.split(os.sep)
    last_two_parts = path_parts[-2:-1] + [os.path.basename(file_path).replace('.csv', '')]
    output_file_name = '_'.join(last_two_parts) + '_plot.png'
    output_file = os.path.join(output_dir, output_file_name)

    # プロットを保存
    plt.savefig(output_file)
    print(f"Plot saved to {output_file}")
    plt.show()
    plt.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Plot sensor data from a CSV file.')
    parser.add_argument('input_file', type=str, help='Path to the CSV file with sensor data')
    parser.add_argument('--output_dir', '-o', default="../../datas/senser_data_plots/", type=str, help='Path to the directory where the plot will be saved')
    parser.add_argument('--japan_time', '-j', action='store_true', help='Convert timestamps to Japan time (UTC+9)')

    args = parser.parse_args()
    plot_sensor_data(args.input_file, args.output_dir, args.japan_time)
