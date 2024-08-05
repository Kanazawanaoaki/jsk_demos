import argparse
from PIL import Image
import openai
import io

# OpenAI APIキーを設定します
openai.api_key = 'YOUR_OPENAI_API_KEY'

def generate_image_description(image_path):
    # 画像を読み込みます
    image = Image.open(image_path)

    # 画像をバイナリデータに変換します
    image_bytes = io.BytesIO()
    image.save(image_bytes, format=image.format)
    image_bytes = image_bytes.getvalue()

    # OpenAI APIを使用して画像の説明を生成します
    response = openai.Image.create(
        file=image_bytes,
        file_format=image.format,
        purpose='description'
    )

    # APIレスポンスを確認します
    if response.status_code == 200:
        description = response['choices'][0]['text']
        print("画像の説明:", description)
    else:
        print("エラーが発生しました:", response.status_code, response.text)

if __name__ == "__main__":
    # コマンドライン引数の解析
    parser = argparse.ArgumentParser(description='画像の説明を生成するプログラム')
    parser.add_argument('image_path', type=str, help='画像ファイルのパス')
    args = parser.parse_args()

    # 画像の説明を生成します
    generate_image_description(args.image_path)
