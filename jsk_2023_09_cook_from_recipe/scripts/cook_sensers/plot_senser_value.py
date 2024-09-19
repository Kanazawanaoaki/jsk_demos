import argparse
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime, timezone, timedelta

def convert_timestamp_to_japan_time(timestamp):
    utc_dt = datetime.fromtimestamp(timestamp, tz=timezone.utc)
    japan_time = utc_dt + timedelta(hours=9)
    return japan_time

def plot_sensor_data(file_path, japan_time):
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
    plt.show()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Plot sensor data from a CSV file.')
    parser.add_argument('file_path', type=str, help='Path to the CSV file containing sensor data')
    parser.add_argument('--japan_time', '-j', action='store_true', help='Convert timestamps to Japan time (UTC+9)')

    args = parser.parse_args()
    plot_sensor_data(args.file_path, args.japan_time)
