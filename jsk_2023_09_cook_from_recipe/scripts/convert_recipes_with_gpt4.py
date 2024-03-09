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

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-k','--key', default="", help="受け取ったAPI key")
    # parser.add_argument('-p','--prompt', default="../recipes/prompts/egg-recipes-jp.txt", help="プロンプトテキストへのパス")
    # parser.add_argument('-r','--recipe', default="../recipes/new_recipes/butter-sunny-jp.txt", help="未知のレシピのテキストへのパス")
    # parser.add_argument('-l','--language', default="jp", help="使用する自然言語の言語")
    parser.add_argument('-p','--prompt', default="../recipes/prompts/egg-recipes.txt", help="プロンプトテキストへのパス")
    parser.add_argument('-r','--recipe', default="../recipes/new_recipes/butter-sunny.txt", help="未知のレシピのテキストへのパス")
    parser.add_argument('-l','--language', choices=['en', 'jp'], default="en", help="使用する自然言語の言語 (en, jp)")
    parser.add_argument('-t','--temperature', default=0.0, type=float)

    args = parser.parse_args()
    openai.api_key = args.key
    temperature = args.temperature
    prompt_text_path = args.prompt
    recipe_text_path = args.recipe
    use_lang = args.language

    prompt_text = read_text_from_file(prompt_text_path)
    recipe_text = read_text_from_file(recipe_text_path)

    ### jp
    if use_lang == "jp":
        input_prompt = prompt_text + "\n[レシピ]\n" + recipe_text + "[関数シーケンス]"
    elif use_lang == "en":
        input_prompt = prompt_text + "\n[Recipe]\n" + recipe_text + "[Function Sequence]"

    # 会話履歴を格納するためのリストを初期化
    conversation_history = []

    print("プロンプト:")
    print(input_prompt)
    generated_text = generate_text(input_prompt, conversation_history, temperature)
    print("\n応答:")
    print(generated_text)

    # while True:
    #     # ユーザーに質問を入力させる
    #     input_prompt = input("プロンプト: ")
    #     generated_text = generate_text(input_prompt, conversation_history, temperature)
    #     print("応答:", generated_text)
