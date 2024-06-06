#!/usr/bin/env python

import argparse
import open3d as o3d
import numpy as np
import os

def process_binary_pcd(pcd):
    # 点群のnumpy配列を取得
    points = np.asarray(pcd.points)
    colors = np.asarray(pcd.colors)

    # 有効なポイントのみをフィルタリング（NaNを含まないポイント）
    # valid_points = points[np.isfinite(points).all(axis=1)]
    valid_indices = np.isfinite(points).all(axis=1) & np.isfinite(colors).all(axis=1)
    valid_points = points[valid_indices]
    valid_colors = colors[valid_indices]


    # 有効なポイントを新しい点群に設定
    valid_pcd = o3d.geometry.PointCloud()
    valid_pcd.points = o3d.utility.Vector3dVector(valid_points)
    valid_pcd.colors = o3d.utility.Vector3dVector(valid_colors)

    # 新しい点群情報を出力
    print(f"Valid PointCloud with {len(valid_pcd.points)} points.")
    print(f"Bounding box: {valid_pcd.get_min_bound()}, {valid_pcd.get_max_bound()}")
    print(f"Center: {valid_pcd.get_center()}")

    return valid_pcd

def visualize_pcd_files(folder_path):
    pcd_lists = []
    for filename in os.listdir(folder_path):
        if filename.endswith(".pcd"):
            pcd_file_path = os.path.join(folder_path, filename)
            pcd = o3d.io.read_point_cloud(pcd_file_path)
            valid_pcd = process_binary_pcd(pcd)
            print(f"Visualizing: {pcd_file_path}")
            pcd_lists.append(valid_pcd)
    o3d.visualization.draw_geometries(pcd_lists)

def main():
    parser = argparse.ArgumentParser(description="Open a point cloud file using Open3D")
    parser.add_argument("folder", type=str, help="Path to the folder containing PCD files.")
    args = parser.parse_args()

    visualize_pcd_files(args.folder)

if __name__ == "__main__":
    main()
