import os
import argparse
import rosbag
import csv
from pathlib import Path
from tqdm import tqdm

def read_rosbag(bag_path, topics, output_dir):
    # rosbagファイルの名前を抽出
    bag_name = Path(bag_path).stem

    # 出力ディレクトリを作成 (rosbagファイル名のフォルダ)
    bag_output_dir = os.path.join(output_dir, bag_name)
    os.makedirs(bag_output_dir, exist_ok=True)
    print("made new directory in {}".format(bag_output_dir))

    # rosbagを開く
    with rosbag.Bag(bag_path, 'r') as bag:
        for topic in topics:
            # output_file = os.path.join(bag_output_dir, topic.replace('/', '_') + '.csv')
            output_file = os.path.join(bag_output_dir, topic.replace('/', '') + '_data.csv')

            # CSVファイルを書き込みモードで開く
            with open(output_file, mode='w', newline='') as csvfile:
                csv_writer = csv.writer(csvfile)
                # ヘッダーを書き込む
                csv_writer.writerow(['Timestamp', 'Value'])

                # # トピックのメッセージを全て取得
                # messages = bag.read_messages(topics=[topic])
                # messages = list(messages)  # メッセージ数を取得するために一度リスト化
                # for topic, msg, t in tqdm(messages, desc=f'Processing {topic}'):

                # トピックのメッセージを全て取得
                for topic, msg, t in tqdm(bag.read_messages(topics=[topic]), desc=f'Processing {topic}'):
                # for topic, msg, t in bag.read_messages(topics=[topic]):
                    # 必要に応じてmsgのデータを修正
                    # 例えば、msg.dataが使える場合は以下のように
                    csv_writer.writerow([t.to_sec(), msg.data.data])

            print("data is saved in {}".format(output_file))

def main():
    # argparseの設定
    parser = argparse.ArgumentParser(description='Extract topics from rosbag and save as CSV files.')
    parser.add_argument('-b', '--bag', required=True, help='Path to the input rosbag file.')
    parser.add_argument('-o', '--output', default="../../datas/sensor_datas/" , help='Directory to save the output CSV files.')
    # parser.add_argument('-t', '--topics', nargs='+', required=True, help='List of topics to extract.')

    args = parser.parse_args()

    topics = ["/timestamped_cal_gas", "/timestamped_gas_v2_102b", "/timestamped_gas_v2_302b", "/timestamped_gas_v2_502b", "/timestamped_gas_v2_702b", "/timestamped_tgs_2600_analog", "/timestamped_tgs_2602_analog", "/timestamped_tgs_2603_analog"]

    # rosbagを読み込んでトピックを抽出しCSVとして保存
    read_rosbag(args.bag, topics, args.output)

if __name__ == '__main__':
    main()

