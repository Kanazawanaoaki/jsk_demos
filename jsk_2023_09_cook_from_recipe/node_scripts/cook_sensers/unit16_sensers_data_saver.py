#!/usr/bin/env python

import rospy
from std_msgs.msg import UInt16
from std_srvs.srv import Empty, EmptyResponse
import csv
import os
import yaml
from datetime import datetime

# グローバル変数
is_saving = False
csv_files = {}

# YAMLファイルからトピックを読み込む
def load_topics(config_file):
    with open(config_file, 'r') as f:
        config = yaml.safe_load(f)
    return config['topics']

# CSVファイルの準備
def initialize_csv(topic_name, save_path):
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    save_path_with_timestamp = os.path.join(save_path, f'data_{timestamp}')

    # ディレクトリを作成
    if not os.path.exists(save_path_with_timestamp):
        os.makedirs(save_path_with_timestamp)

    csv_file = os.path.join(save_path_with_timestamp, f'{topic_name[1:]}_data.csv')  # トピック名に基づいてファイル名を作成
    with open(csv_file, 'w') as f:
        writer = csv.writer(f)
        # ヘッダー行の書き込み
        writer.writerow(['Timestamp', 'Value'])
    return csv_file

# コールバック関数
def callback(msg, csv_file):
    if not is_saving:
        return

    current_time = rospy.get_rostime().to_sec()  # 現在の時刻を取得
    value = msg.data

    # CSVにデータを書き込む
    with open(csv_file, 'a') as f:
        writer = csv.writer(f)
        writer.writerow([current_time, value])

def start_saving(request):
    global is_saving
    is_saving = True
    rospy.loginfo("データ保存を開始しました")
    return EmptyResponse()

def stop_saving(request):
    global is_saving
    is_saving = False
    rospy.loginfo("データ保存を停止しました")
    return EmptyResponse()

def listener():
    global is_saving
    global csv_files

    rospy.init_node('uint16_sensors_data_saver', anonymous=True)

    # パラメータの取得
    config_file = rospy.get_param('~config_file', 'config/topics.yaml')
    save_path = rospy.get_param('~save_path', os.path.expanduser('~'))  # デフォルトはユーザーディレクトリ

    # YAMLファイルからトピックを読み込み
    topics = load_topics(config_file)

    # CSVファイルの準備
    csv_files = {}
    for topic in topics:
        topic_name = topic['name']
        csv_file = initialize_csv(topic_name, save_path)
        csv_files[topic_name] = csv_file
        rospy.Subscriber(topic_name, UInt16, callback, callback_args=csv_file)

    # サービスサーバーのセットアップ
    rospy.Service('~start_saving', Empty, start_saving)
    rospy.Service('~stop_saving', Empty, stop_saving)

    # ノードを停止しないようにループ
    rospy.spin()

if __name__ == '__main__':
    try:
        listener()
    except rospy.ROSInterruptException:
        pass
