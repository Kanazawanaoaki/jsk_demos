import os
import argparse

def delete_png_files(directory, start_number, delete_before=False):
    """
    指定したディレクトリ内の.pngファイルを削除する。

    Args:
        directory (str): 対象のディレクトリパス。
        start_number (int): 基準となる番号。
        delete_before (bool): Trueの場合、start_numberより小さい番号のファイルを削除。
                              Falseの場合、start_number以上のファイルを削除。
    """
    try:
        files = os.listdir(directory)
        for file in files:
            if file.endswith(".png") and file[:-4].isdigit():
                file_number = int(file[:-4])
                if (delete_before and file_number < start_number) or (not delete_before and file_number >= start_number):
                    file_path = os.path.join(directory, file)
                    os.remove(file_path)
                    print(f"Deleted: {file_path}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Delete .png files based on a specified number.")
    parser.add_argument("directory", type=str, help="The target directory containing .png files.")
    parser.add_argument("start_number", type=int, help="The number used as a threshold for deletion.")
    parser.add_argument("--before", "-b", action="store_true", help="Delete files with numbers smaller than the specified value.")
    args = parser.parse_args()

    # 実行
    delete_png_files(args.directory, args.start_number, args.before)
