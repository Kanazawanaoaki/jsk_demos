#! /usr/bin/python3

import argparse
from PIL import Image

def convert_jpeg_to_png(input_image_path, output_image_path):
    # 画像の読み込み
    image = Image.open(input_image_path)

    # PNG形式で保存
    image = image.convert("P", palette=Image.ADAPTIVE, colors=256)
    image.save(output_image_path, 'PNG')
    print(f"画像を保存しました: {output_image_path}")

def main():
    # argparseのセットアップ
    parser = argparse.ArgumentParser(description='JPEG画像をPNG画像に変換します。')
    parser.add_argument('--input_image', '-i', default="/home/kanazawa/Downloads/20240614_tracking_test/20240531_onion_01_rs_data/1717144131850_mask.jpg", type=str, help='入力JPEG画像のパス')
    parser.add_argument('--output_image', '-o', default="/home/kanazawa/Downloads/20240614_tracking_test/20240531_onion_01_rs_data/1717144131850_conveted_mask.png", type=str, help='出力PNG画像のパス')

    args = parser.parse_args()

    # 画像の変換
    convert_jpeg_to_png(args.input_image, args.output_image)

if __name__ == '__main__':
    main()

