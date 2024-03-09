import openai
import argparse

def generate_text(prompt, conversation_history, temperature):
    # プロンプトを会話履歴に追加
    conversation_history.append({"role": "user", "content": prompt})

    # GPT-4モデルを使用する場合
    response = openai.ChatCompletion.create(
        model="gpt-4",
        temperature=temperature,
        messages=conversation_history
    )
    message = ""

    for choice in response.choices:
        message += choice.message['content']

    # 応答文を会話履歴に追加
    conversation_history.append({"role": "assistant", "content": message})
    return message

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-k','--key', default="", help="受け取ったAPI key")
    parser.add_argument('-t','--temperature', default=0.0, type=float)

    args = parser.parse_args()
    openai.api_key = args.key
    temperature = args.temperature

    # 会話履歴を格納するためのリストを初期化
    conversation_history = []

    while True:
        # ユーザーに質問を入力させる
        input_prompt = input("プロンプト: ")
        generated_text = generate_text(input_prompt, conversation_history, temperature)
        print("応答:", generated_text)
