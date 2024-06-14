#!/usr/bin/env python

import cv2
import numpy as np

# import matplotlib.pyplot as plt
# from mpl_toolkits.mplot3d import Axes3D
import open3d as o3d

import argparse
import os

def read_cam_matrix(cam_file):
    with open(cam_file, 'r') as f:
        lines = f.readlines()
    cam_K = np.array([[float(i) for i in line.split()] for line in lines])
    print(cam_K)
    return cam_K

def create_colored_point_cloud(rgb_image, depth_image, mask_image, cam_file, use_mask=True):
# def create_point_cloud(rgb_image, depth_image, mask_image, cam_file):
    # RGB画像の読み込み
    rgb = cv2.imread(rgb_image)

    # Depth画像の読み込み
    depth = cv2.imread(depth_image, cv2.IMREAD_UNCHANGED).astype(np.float32) / 1000.0  # mmをmに変換
    # Mask画像の読み込み
    mask = cv2.imread(mask_image, cv2.IMREAD_UNCHANGED)
    if len(mask.shape) == 3 and mask.shape[2] == 3:
        mask = cv2.cvtColor(mask, cv2.COLOR_BGR2GRAY)
        print("Converted 3-channel mask to grayscale.")

    # カメラ行列の取得
    cam_K = read_cam_matrix(cam_file)

    # 画像サイズの取得
    height, width = depth.shape

    # 画像座標からカメラ座標への変換
    ys, xs = np.meshgrid(range(height), range(width), indexing='ij')
    if use_mask:
        xs = xs[mask > 0]
        ys = ys[mask > 0]
        zs = depth[mask > 0]
    else:
        xs = xs[mask >= 0]
        ys = ys[mask >= 0]
        zs = depth[mask >= 0]

    # カメラ座標系から3D点を計算
    points_cam = np.dot(np.linalg.inv(cam_K), np.vstack((xs * zs, ys * zs, zs)))


    # 3D点をワールド座標系に変換
    points_world = points_cam.T
    # return points_world

    # RGB情報を取得
    if use_mask:
        colors = rgb[mask > 0] / 255.0  # Open3DではRGB値を[0, 1]の範囲で扱う
    else:
        # colors = rgb[mask >= 0] / 255.0  # Open3DではRGB値を[0, 1]の範囲で扱う
        array_3d = mask[:,:, np.newaxis] / 5.0
        array_zeros_1 = np.zeros((480, 640))
        array_zeros_2 = np.zeros((480, 640))
        array_concatenated = np.concatenate((array_zeros_1[:, :, np.newaxis], array_zeros_2[:, :, np.newaxis], array_3d), axis=2)
        print(array_3d.max())
        # array_3d = np.repeat(array_3d, 3, axis=2)
        colors = rgb + array_concatenated
        colors = colors[mask>=0]/255.0


    # Open3DのPointCloudオブジェクトを作成
    point_cloud = o3d.geometry.PointCloud()
    point_cloud.points = o3d.utility.Vector3dVector(points_world)
    point_cloud.colors = o3d.utility.Vector3dVector(colors[:, ::-1])  # Open3DではBGRではなくRGBの順序を想定しているため、色の順序を反転させる

    return point_cloud

# 点群を描画する関数
def plot_point_cloud(point_cloud):
    fig = plt.figure()
    ax = fig.add_subplot(111, projection='3d')
    ax.scatter(point_cloud[:,0], point_cloud[:,1], point_cloud[:,2], c=point_cloud[:,2], cmap='viridis')
    ax.set_xlabel('X')
    ax.set_ylabel('Y')
    ax.set_zlabel('Z')
    plt.show()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process files in specified directories.')
    parser.add_argument('--rgb_file_path', '-r', type=str, help='Input directory containing subdirectories with files', default='/home/kanazawa/ros/known_object_ws/src/known_object_ros/data/object_datas/data_20240514_test_03_for_train/rgb/1716536261013376474.png')

    args = parser.parse_args()
    rgb_file_path = args.rgb_file_path

    base_dir = os.path.dirname(os.path.dirname(rgb_file_path))
    filename_with_extension = os.path.basename(rgb_file_path)
    filename_without_extension = os.path.splitext(filename_with_extension)[0]
    file_name = filename_without_extension.split('_')[-1]
    depth_dir = os.path.join(base_dir, "depth")
    depth_file_path = os.path.join(depth_dir, f"{file_name}.png")
    mask_dir = os.path.join(base_dir, "mask")
    mask_file_path = os.path.join(mask_dir, f"{file_name}.png")

    cam_file_path = os.path.join(base_dir, "cam_K.txt")

    colored_point_cloud = create_colored_point_cloud(rgb_file_path, depth_file_path, mask_file_path, cam_file_path, use_mask=False)
    # 点群を表示
    o3d.visualization.draw_geometries([colored_point_cloud])
