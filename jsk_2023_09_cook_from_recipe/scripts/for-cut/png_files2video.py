#!/usr/bin/env python

import os
import argparse
from PIL import Image, ImageDraw, ImageFont
import cv2
import numpy as np
from tqdm import tqdm

def convert_images_to_video(input_dir, output_file):
    # 入力ディレクトリ内のすべてのpngファイルを取得し、名前の数字順にソート
    files = sorted(
        [f for f in os.listdir(input_dir) if f.endswith(".png")],
        key=lambda x: int(''.join(filter(str.isdigit, x)))
    )

    if not files:
        print("No PNG files found in the input directory.")
        return

    # 最初の画像でフレームサイズを取得
    first_image_path = os.path.join(input_dir, files[0])
    with Image.open(first_image_path) as img:
        frame_size = img.size

    # 出力動画のパス
    output_video = os.path.join(input_dir, output_file)

    # 動画を作成するためのVideoWriterを初期化
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')  # MP4形式
    fps = 30  # フレームレート
    video_writer = cv2.VideoWriter(output_video, fourcc, fps, frame_size)

    # フォント設定
    font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"  # フォントパス
    font = ImageFont.truetype(font_path, 24)

    for file_name in tqdm(files, desc="process images"):
        png_path = os.path.join(input_dir, file_name)

        with Image.open(png_path) as img:
            # RGBに変換
            rgb_img = img.convert("RGB")

            # ファイル名の数字を取得して描画
            file_number = ''.join(filter(str.isdigit, file_name))
            draw = ImageDraw.Draw(rgb_img)
            draw.text((10, 10), file_number, fill="white", font=font)

            # OpenCVの形式に変換
            frame = cv2.cvtColor(np.array(rgb_img), cv2.COLOR_RGB2BGR)

            # フレームを動画に書き込む
            video_writer.write(frame)

            # print(f"Processed: {png_path}")

    video_writer.release()
    print(f"Video saved to {output_video}")

def main():
    # argparseで引数を定義
    parser = argparse.ArgumentParser(description="Convert PNG files to a video with file numbers in the corner")
    parser.add_argument("input_dir", type=str, help="Input directory containing PNG files")
    parser.add_argument("--output_name", "-o", type=str, default="output_video.mp4", help="Ouput video file name")

    # 引数を解析
    args = parser.parse_args()

    # 変換処理を実行
    convert_images_to_video(args.input_dir, args.output_name)

if __name__ == "__main__":
    main()
