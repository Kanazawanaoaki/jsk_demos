import argparse
from openai import AzureOpenAI

def main():
    # ===== argparse で引数を定義 =====
    parser = argparse.ArgumentParser(
        description="Azure OpenAI にチャットを投げる簡単なスクリプト"
    )
    parser.add_argument(
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

    args = parser.parse_args()

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
                "content": "私はパリにいく予定です．何を見るべきでしょうか？",
            }
        ],
        max_completion_tokens=16384,
        model=args.deployment,
    )

    print(response.choices[0].message.content)


if __name__ == "__main__":
    main()
