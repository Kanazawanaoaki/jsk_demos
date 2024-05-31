#!/usr/bin/env python

import argparse
import open3d as o3d

def main():
    parser = argparse.ArgumentParser(description="Open a point cloud file using Open3D")
    parser.add_argument("file", type=str, help="Path to the point cloud file")
    args = parser.parse_args()

    # ファイルを読み込む
    point_cloud = o3d.io.read_point_cloud(args.file)

    # 点群を表示する
    o3d.visualization.draw_geometries([point_cloud])

if __name__ == "__main__":
    main()
