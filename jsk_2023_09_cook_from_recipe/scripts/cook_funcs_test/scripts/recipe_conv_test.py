import os
import argparse
from openai import AzureOpenAI

def read_text_from_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            text = file.read()
        return text
    except FileNotFoundError:
        print(f"Error: File not found at {file_path}")
        return None
    except Exception as e:
        print(f"An error occurred: {str(e)}")
        return None

def extract_file_name(file_path):
    file_name = os.path.splitext(os.path.basename(file_path))[0]
    return file_name

def main():
    # ===== argparse で引数を定義 =====
    parser = argparse.ArgumentParser(
        description="Azure OpenAI でレシピを関数に変換するスクリプト"
    )
    parser.add_argument(
        "-k",
        "--api-key",
        required=True,
        help="Azure OpenAI の API キーを指定してください",
    )
    parser.add_argument(
        "--endpoint",
        default="https://kanazawa-openai-api-test-east-us2.openai.azure.com/",
        help="Azure OpenAI のエンドポイントURL（省略時はデフォルトを使用）",
    )
    parser.add_argument(
        "--deployment",
        default="gpt-5.1",
        help="使用するデプロイメント名（省略時は gpt-5.1）",
    )
    parser.add_argument(
        "--api-version",
        default="2024-12-01-preview",
        help="API Version（省略時は 2024-12-01-preview）",
    )
    parser.add_argument(
        '-p',
        '--prompt',
        default="../texts/prompts/egg-recipes-prompt-update-fixed-20240729.txt",
        help="プロンプトテキストへのパス"
    )
    parser.add_argument(
        '-r',
        '--recipe',
        default="../texts/en_recipes/sauteed-broccoli.txt",
        help="未知のレシピのテキストへのパス"
    )
    parser.add_argument(
        '-o',
        '--output_dir',
        default="../texts/output_seqs/",
        help="出力のフォルダへのパス"
    )


    args = parser.parse_args()

    prompt_text_path = args.prompt
    recipe_text_path = args.recipe
    output_dir_path = args.output_dir


    ## 入力するテキストプロンプトを作成
    prompt_text = read_text_from_file(prompt_text_path)
    recipe_text = read_text_from_file(recipe_text_path)
    input_text = prompt_text + "\n[Recipe]\n" + recipe_text + "[Function Sequence]"
    # print(input_text)

    # ===== AzureOpenAI クライアントを作成 =====
    client = AzureOpenAI(
        api_version=args.api_version,
        azure_endpoint=args.endpoint,
        api_key=args.api_key,
    )

    # ===== 通常通り Chat Completions を実行 =====
    response = client.chat.completions.create(
        messages=[
            {
                "role": "system",
                "content": "You are a helpful assistant.",
            },
            {
                "role": "user",
                "content": input_text,
            }
        ],
        max_completion_tokens=16384,
        model=args.deployment,
        temperature=0,
        seed=42,
    )

    output_text = response.choices[0].message.content
    print(output_text)

    ## 出力結果を保存
    prompt_name = extract_file_name(prompt_text_path)
    recipe_name = extract_file_name(recipe_text_path)

    output_file_path = os.path.join(output_dir_path, f"{args.deployment}_{args.api_version}-{prompt_name}_{recipe_name}_converted.txt")
    with open(output_file_path, 'w', encoding='utf-8') as file:
        file.write(output_text)
    print("\nOutput is saved in {}".format(output_file_path))


if __name__ == "__main__":
    main()
