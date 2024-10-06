import os
import argparse
import rosbag
import csv
from pathlib import Path

import cv2
from cv_bridge import CvBridge
from datetime import datetime

from tqdm import tqdm

# ROSからのメッセージを画像に変換するためのブリッジ
bridge = CvBridge()


def process_image(msg):
    # CompressedImageをOpenCVの画像に変換
    cv_img = bridge.compressed_imgmsg_to_cv2(msg, "bgr8")

    # タイムスタンプの取得
    timestamp_ros = msg.header.stamp
    timestamp_unix = timestamp_ros.to_sec()

    # タイムスタンプを日本時間に変換
    timestamp_jst = datetime.fromtimestamp(timestamp_unix).strftime('%Y-%m-%d %H:%M:%S')

    # タイムスタンプを画像に描画（左上に描画）
    font = cv2.FONT_HERSHEY_SIMPLEX
    text = f"ROS Time: {timestamp_ros}, JST: {timestamp_jst}"
    cv2.putText(cv_img, text, (10, 30), font, 0.5, (255, 255, 255), 2, cv2.LINE_AA) ## 白
    # cv2.putText(cv_img, text, (10, 30), font, 0.5, (0, 0, 0), 1, cv2.LINE_AA) ## 黒

    return cv_img

def save_video(output_filename, image_list, fps=30):
    if not image_list:
        print("No images to save.")
        return

    # 動画の幅と高さを取得
    height, width, layers = image_list[0].shape
    size = (width, height)

    # 動画ファイルの準備
    out = cv2.VideoWriter(output_filename, cv2.VideoWriter_fourcc(*'mp4v'), fps, size)

    # 画像を1フレームずつ動画に書き込む
    for img in image_list:
        out.write(img)

    # 動画ファイルを閉じる
    out.release()

def read_rosbag(bag_path, image_topic, output_dir):
    # rosbagファイルの名前を抽出
    bag_name = Path(bag_path).stem

    if not os.path.exists(bag_path):
        print('Input bagfile {} not exists.'.format(bag_path))
        sys.exit(1)

    # 出力ディレクトリを作成 (rosbagファイル名のフォルダ)
    bag_output_dir = output_dir
    if not os.path.exists(bag_output_dir):
        os.makedirs(bag_output_dir)
        print("made directory in {}".format(bag_output_dir))
    # os.makedirs(bag_output_dir, exist_ok=True)
    output_file = os.path.join(bag_output_dir, bag_name + '_video.mp4')

    print(output_file)

    # 画像のリストを初期化
    image_list = []

    # rosbagを開く
    with rosbag.Bag(bag_path, 'r') as bag:
        # トピックのメッセージを全て取得
        for topic, msg, t in tqdm(bag.read_messages(topics=[image_topic]), desc=f'Processing {image_topic}'):
            img = process_image(msg)
            image_list.append(img)

        save_video(output_file, image_list, fps=30)
        print("data is saved in {}".format(output_file))

def main():
    # argparseの設定
    parser = argparse.ArgumentParser(description='Extract topics from rosbag and save as CSV files.')
    parser.add_argument('-b', '--bag', required=True, help='Path to the input rosbag file.')
    parser.add_argument('-o', '--output', default="../../datas/sensor_data_images/" , help='Directory to save the output CSV files.')
    parser.add_argument('-i', '--image', default="/camera/color/image_raw/compressed", help='Name of image topic.')

    args = parser.parse_args()

    # rosbagを読み込んでトピックを抽出しCSVとして保存
    read_rosbag(args.bag, args.image, args.output)

if __name__ == '__main__':
    main()

