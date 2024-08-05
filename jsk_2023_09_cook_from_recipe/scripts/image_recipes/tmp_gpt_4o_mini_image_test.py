import argparse
import openai
import os
from PIL import Image
import io

# OpenAI APIのバージョン名
version_name = "gpt-4o-mini-2024-07-18"

def generate_image_description(image_bytes):
    # OpenAI APIを使用して画像の説明を生成します
    response = openai.Image.create(
        file=image_bytes,
        model=version_name,
        purpose='description'
    )
    
    # APIレスポンスを確認します
    description = ""
    if response.get("choices"):
        description = response["choices"][0]["text"]
    else:
        print("エラーが発生しました:", response.get("error", "Unknown error"))
    
    return description

def read_image_from_file(file_path):
    try:
        with open(file_path, 'rb') as file:
            image_bytes = file.read()
        return image_bytes
    except FileNotFoundError:
        print(f"Error: File not found at {file_path}")
        return None
    except Exception as e:
        print(f"An error occurred: {str(e)}")
        return None

def extract_file_name(file_path):
    file_name = os.path.splitext(os.path.basename(file_path))[0]
    return file_name

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-k', '--key', required=True, help="受け取ったAPI key")
    parser.add_argument('-i', '--image', required=True, help="画像ファイルのパス")
    parser.add_argument('-o', '--output_dir', default="./", help="出力のフォルダへのパス")
    args = parser.parse_args()

    openai.api_key = args.key
    image_path = args.image
    output_dir_path = args.output_dir

    # 画像を読み込みます
    image_bytes = read_image_from_file(image_path)
    if image_bytes is None:
        exit(1)

    # 画像の説明を生成します
    description = generate_image_description(image_bytes)

    # 結果を表示します
    print("\n画像の説明:")
    print(description)

    # 出力ファイルに保存します
    image_name = extract_file_name(image_path)
    output_file_path = os.path.join(output_dir_path, f"{image_name}_description.txt")
    with open(output_file_path, 'w', encoding='utf-8') as file:
        file.write(description)
    print("\nOutput is saved in {}".format(output_file_path))
