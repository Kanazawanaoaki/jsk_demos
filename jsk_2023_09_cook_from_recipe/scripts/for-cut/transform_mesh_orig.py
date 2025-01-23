import trimesh
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

import os
import argparse

def transform_mesh(mesh_path):
    # メッシュを読み込み
    mesh = trimesh.load(mesh_path)

    materials = None
    # .objファイルを開いて解析
    with open(mesh_path, 'r') as obj_file:
        for line in obj_file:
            # 空行やコメントは無視
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            # マテリアルファイル (mtllib)
            if line.startswith('mtllib'):
                materials = line.split(maxsplit=1)[1]

    # oriented_bounds を計算
    to_origin, extents = trimesh.bounds.oriented_bounds(mesh)

    # メッシュをコピーして変換を適用
    aligned_mesh = mesh.copy()
    aligned_mesh.apply_transform(to_origin)

    # 変換後のメッシュを保存
    # ディレクトリとファイル名に分割
    directory, filename = os.path.split(mesh_path)
    # 拡張子を分離
    name, ext = os.path.splitext(filename)
    # 新しいファイル名を作成
    new_filename = f"{name}_orig_fixed{ext}"
    # 新しいフルパスを作成
    output_path = os.path.join(directory, new_filename)

    # aligned_mesh.export(output_path)
    # 新しい .obj ファイルを書き出す
    with open(output_path, 'w') as out_file:
        # マテリアルファイル情報を追加
        if materials:
            out_file.write(f"mtllib {materials}\n")
        else:
            print("No material file found; skipping mtllib.")

        # メッシュデータを書き込む
        for line in aligned_mesh.export(file_type='obj').splitlines():
            # `mtllib` が重複しないようスキップ
            if line.startswith('mtllib'):
                continue
            out_file.write(line + '\n')

    print(f"Transformed mesh saved to: {output_path}")

def main():
    # argparseで引数を定義
    parser = argparse.ArgumentParser(description="Convert PNG files to a video with file numbers in the corner")
    parser.add_argument("input_mesh", type=str, help="Input directory containing PNG files")

    # 引数を解析
    args = parser.parse_args()

    # 変換処理を実行
    transform_mesh(args.input_mesh)

if __name__ == "__main__":
    main()
