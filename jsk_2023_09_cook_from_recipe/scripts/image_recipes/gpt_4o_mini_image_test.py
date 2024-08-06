import argparse
import base64
import os
from PIL import Image
import matplotlib.pyplot as plt
from openai import OpenAI

# OpenAI APIキーとモデル名の設定
MODEL = "gpt-4o-mini"

def encode_image(image_path):
    """画像ファイルをbase64エンコードする関数"""
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode("utf-8")

def main(image_path, key):
    client = OpenAI(api_key=key)

    # 画像をbase64エンコード
    base64_image = encode_image(image_path)

    # APIリクエストを作成
    response = client.chat.completions.create(
        model=MODEL,
        messages=[
            {"role": "system", "content": "You are a helpful assistant that responds in Markdown. Help me with my math homework!"},
            {"role": "user", "content": [
                {"type": "text", "text": "画像に書かれている内容を文字起こししてください"},
                {"type": "image_url", "image_url": {
                    "url": f"data:image/png;base64,{base64_image}"}
                }
            ]}
        ],
        temperature=0.0,
    )

    # APIからの応答を表示
    print(response.choices[0].message.content)

    # 画像を読み込み、表示する
    img = Image.open(image_path)
    plt.imshow(img)
    plt.axis('off')  # 軸を表示しないようにする
    plt.show()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="OpenAI APIを使って画像に関する説明を生成します。")
    parser.add_argument('-k', '--key', required=True, help="受け取ったAPI key")
    parser.add_argument('-i', '--image', required=True, help="画像ファイルのパス")
    args = parser.parse_args()

    if not os.path.isfile(args.image):
        print(f"Error: File not found at {args.image}")
        exit(1)

    main(args.image, args.key)
