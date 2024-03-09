import argparse
import re
import os

def main(input_file, output_dir_path):
    # ファイル名から拡張子を削除
    # base_name = os.path.splitext(input_file)[0]
    # output_file = f'{base_name}_conv.l'
    base_name = os.path.splitext(os.path.basename(input_file))[0]
    output_file = os.path.join(output_dir_path, f'{base_name}_conv.l')
    print("Input file name is {}".format(base_name))

    # 関数のテキストファイルから読み込み
    with open(input_file, 'r') as file:
        content = file.read()

    # 変数の初期化
    basic_cooking_target_conditions = []

    # 正規表現パターンの定義
    pattern = r"([-\w]+)\(([^)]+)\)"

    # マッチした部分をリストに格納
    matches = re.findall(pattern, content)
    print(content)

    # マッチした行をループで処理
    for match in matches:
        # print(match)

        function, args = match
        # 引数をカンマで分割
        args = [arg.strip() for arg in args.split(',')]
        # 引数を大文字に変換
        args = [arg.upper() for arg in args]

        if function == 'pour': ## pour(ingredient, vessel) -> ((IN ingredient vessel))
            basic_cooking_target_conditions.append([f'((IN {args[0]} {args[1]}))'])
        elif function == 'mix': ## mix(ingredient, ingredient, mixture, vessel, tool) -> ((MIXED ?MIXTURE ?ING-ONE ?ING-TWO ?TOOL) (IN ?MIXTURE ?VESSEL))
            basic_cooking_target_conditions.append([f'((MIXED {args[2]} {args[0]} {args[1]} {args[4]}) (IN {args[2]} {args[3]}))'])
        elif function == 'turn-on-stove': ## turn-on-stove(vessel) -> (STOVE-ON ?VESSEL)
            basic_cooking_target_conditions.append([f'((STOVE-ON {args[0]}))'])
        elif function == 'set-stove': ## set-stove(state, vessel) -> ((SET-STOVE ?AFTER ?VESSEL))
            basic_cooking_target_conditions.append([f'((SET-STOVE {args[0]} {args[1]}))'])
        elif function == 'turn-off-stove': ## turn-off-stove(vessel) -> (NOT (STOVE-ON ?VESSEL))
            basic_cooking_target_conditions.append([f'((NOT (STOVE-ON {args[0]})))'])
        elif function == 'stir': ## stir(ingredient, state, tool) -> ((STIRRED ?OBJECT ?STATE ?TOOL))
            basic_cooking_target_conditions.append([f'((STIRRED {args[0]} {args[1]} {args[2]}))'])
        elif function == 'heat': ## heat(ingredient, state) -> ((HEATED ?OBJECT ?STATE))
            basic_cooking_target_conditions.append([f'((HEATED {args[0]} {args[1]}))'])
        elif function == 'cook': ## cook(ingredient, state) -> ((COOKED ?OBJECT ?STATE))
            basic_cooking_target_conditions.append([f'((COOKED {args[0]} {args[1]}))'])
        elif function == 'boil': ## boil(ingredient, state) -> ((BOILED ?OBJECT ?STATE))
            basic_cooking_target_conditions.append([f'((BOILED {args[0]} {args[1]}))'])
        elif function == 'stir-fry': ## sitr-fry(ingredient, state, tool) -> ((STIR-FRIED ?INPUT ?STATE ?TOOL))
            basic_cooking_target_conditions.append([f'((STIR-FRIED {args[0]} {args[1]} {args[2]}))'])

    # 結果をファイルに書き込む
    # print(basic_cooking_target_conditions)
    with open(output_file, 'w') as file:
        file.write('(setq *basic-cooking-target-conditions* (list\n')
        for condition in basic_cooking_target_conditions:
            file.write(' ' * 41 + f'\'{condition[0]}\n')
            print(f'\'{condition[0]}')
        file.write(' ' * 41 + '))\n')

    print("Output is saved in {}".format(output_file))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Cooking script')
    parser.add_argument('--input', '-i', default='../recipes/output_seqs/prompt_poached-egg.txt', help='Input file name')
    parser.add_argument('-o','--output_dir', default="../recipes/output_conditions/", help="Path to output directory")
    args = parser.parse_args()
    main(args.input, args.output_dir)
