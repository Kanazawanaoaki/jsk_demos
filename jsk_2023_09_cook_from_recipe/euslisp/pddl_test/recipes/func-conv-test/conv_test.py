import argparse
import re
import os

def main(input_file):
    # ファイル名から拡張子を削除
    base_name = os.path.splitext(input_file)[0]
    output_file = f'{base_name}-conv.l'

    # 関数のテキストファイルから読み込み
    with open(input_file, 'r') as file:
        content = file.read()

    # 変数の初期化
    basic_cooking_target_conditions = []

    # # 正規表現パターンの定義
    # pattern = r"(\w+)\(([^,]+), ([^)]+)\)"
    # 正規表現パターンの定義
    # pattern = r"(\w+)\(([^)]+)\)"
    pattern = r"([-\w]+)\(([^)]+)\)"

    # マッチした部分をリストに格納
    matches = re.findall(pattern, content)
    print(content)

    # マッチした行をループで処理
    for match in matches:
        print(match)

        # function, arg1, arg2 = match
        # # arg1 と arg2 を大文字に変換
        # arg1 = arg1.upper()
        # arg2 = arg2.upper()

        function, args = match
        # 引数をカンマで分割
        args = [arg.strip() for arg in args.split(',')]
        # 引数を大文字に変換
        args = [arg.upper() for arg in args]

        if function == 'pour':
            basic_cooking_target_conditions.append([f'((IN {args[0]} {args[1]}))'])
        elif function == 'mix':
            basic_cooking_target_conditions.append([f'((MIXED {args[2]} {args[0]} {args[1]} {args[4]}) (IN {args[2]} {args[3]}))'])
        elif function == 'set-stove':
            basic_cooking_target_conditions.append([f'((SET-STOVE {args[0]}))'])
        elif function == 'stir':
            basic_cooking_target_conditions.append([f'((STIRRED {args[0]} {args[1]} {args[2]}))'])
        elif function == 'heat':
            basic_cooking_target_conditions.append([f'((HEATED {args[0]} {args[1]}))'])
        elif function == 'cook':
            basic_cooking_target_conditions.append([f'((COOKED {args[0]} {args[1]}))'])
        elif function == 'boil':
            basic_cooking_target_conditions.append([f'((BOILED {args[0]} {args[1]}))'])
        elif function == 'stir-fry':
            basic_cooking_target_conditions.append([f'((STIR-FRIED {args[0]} {args[1]} {args[2]}))'])


    # 結果をファイルに書き込む
    with open(output_file, 'w') as file:
        file.write('(setq *basic-cooking-target-conditions* (list\n')
        for condition in basic_cooking_target_conditions:
            file.write(' ' * 41 + f'\'{condition[0]}\n')
        file.write(' ' * 41 + '))\n')

    # print(f'Results written to {output_file}')
    # # 結果をファイルに書き込む
    # with open('output.l', 'w') as file:
    #     for condition in basic_cooking_target_conditions:
    #         file.write(f'(({", ".join(condition)}))\n')

    # # 結果を表示
    # print(basic_cooking_target_conditions)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Cooking script')
    parser.add_argument('--input', '-i', default='functions.txt', help='Input file name')
    args = parser.parse_args()
    main(args.input)
