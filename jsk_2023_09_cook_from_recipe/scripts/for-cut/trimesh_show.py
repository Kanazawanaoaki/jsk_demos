import trimesh
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

import os
import argparse

def show_mesh(mesh_path):
    # メッシュを読み込み
    mesh = trimesh.load(mesh_path)

    # メッシュの頂点座標を取得（可視化用）
    vertices = mesh.vertices

    # プロット
    fig = plt.figure(figsize=(10, 7))
    ax = fig.add_subplot(111, projection='3d')

    # メッシュの頂点をプロット
    ax.scatter(vertices[:, 0], vertices[:, 1], vertices[:, 2], color='blue', s=1, label='Vertices')

    # 原点をプロット
    ax.scatter(0, 0, 0, color='red', s=100, label='Origin')

    # 軸ラベル
    ax.set_xlabel('X-axis')
    ax.set_ylabel('Y-axis')
    ax.set_zlabel('Z-axis')

    # 凡例を表示
    ax.legend()

    # グリッドを表示
    ax.grid(True)

    # 表示
    plt.show()

def main():
    # argparseで引数を定義
    parser = argparse.ArgumentParser(description="Convert PNG files to a video with file numbers in the corner")
    parser.add_argument("input_mesh", type=str, help="Input directory containing PNG files")

    # 引数を解析
    args = parser.parse_args()

    # 変換処理を実行
    show_mesh(args.input_mesh)

if __name__ == "__main__":
    main()
