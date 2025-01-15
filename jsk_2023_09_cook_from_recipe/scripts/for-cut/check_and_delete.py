import os
import argparse

def delete_png_files(directory, start_number):
    """
    指定したディレクトリ内の指定した番号以降の.pngファイルを削除する。

    Args:
        directory (str): 対象のディレクトリパス。
        start_number (int): この番号以降のファイルを削除する。
    """
    try:
        files = os.listdir(directory)
        for file in files:
            # ファイル名が数字で構成され、拡張子が .png の場合
            if file.endswith(".png") and file[:-4].isdigit():
                file_number = int(file[:-4])  # 拡張子を除いた部分を数字として取得
                if file_number >= start_number:
                    file_path = os.path.join(directory, file)
                    os.remove(file_path)
                    print(f"Deleted: {file_path}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Delete .png files with numbers greater than or equal to a specified value.")
    parser.add_argument("directory", type=str, help="The target directory containing .png files.")
    parser.add_argument("start_number", type=int, help="The starting number for deletion.")
    args = parser.parse_args()

    # 実行
    delete_png_files(args.directory, args.start_number)
