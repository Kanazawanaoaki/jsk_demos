#!/usr/bin/env python

import rospy
import sensor_msgs.point_cloud2 as pc2
from sensor_msgs.msg import PointCloud2
from std_srvs.srv import Trigger, TriggerResponse
import open3d as o3d

import numpy as np
import ctypes
import struct
from tqdm import tqdm

class PointCloudSaver:
    def __init__(self):
        self.pointcloud_data = None
        self.pointcloud_received = False

        # ROS Nodeの初期化
        rospy.init_node('pointcloud_saver')

        # ROS サービスの作成
        self.service = rospy.Service('save_pointcloud', Trigger, self.save_pointcloud_callback)

        # 点群データの受信用のSubscriberを作成
        rospy.Subscriber('/kinect_head_remote/depth_registered/points', PointCloud2, self.pointcloud_callback)

    def pointcloud_callback(self, data):
        # ポイントクラウドデータを受信した時のコールバック関数
        self.pointcloud_data = data
        self.pointcloud_received = True

    def save_pointcloud_callback(self, request):
        # サービスコールが来た時のコールバック関数
        rospy.loginfo("service call.")
        while not self.pointcloud_received and not rospy.is_shutdown():
            rospy.sleep(0.1)

        if self.pointcloud_received:
            # 点群データをPointCloud2オブジェクトとして取得
            pointcloud = self.pointcloud_data

            # 時刻をチェックし、指定された時刻以降のデータをフィルタリング
            # ここに時刻チェックのコードを追加してください

            # # ポイントクラウドデータを保存
            # pcd = pc2.read_points(pointcloud, skip_nans=True)
            # points = []
            # for p in pcd:
            #     points.append([p[0], p[1], p[2]])
            # pcd = o3d.geometry.PointCloud()
            # pcd.points = o3d.utility.Vector3dVector(points)
            # o3d.io.write_point_cloud("pointcloud.pcd", pcd)

            # pcd = pc2.read_points(pointcloud, field_names=("x", "y", "z", "rgb"), skip_nans=True)
            # points = []
            # for p in pcd:
            #     rgb = p[3]  # RGBA format
            #     r = int((rgb >> 16) & 0x0000ff)
            #     g = int((rgb >> 8) & 0x0000ff)
            #     b = int((rgb & 0x0000ff))
            #     points.append([p[0], p[1], p[2], r / 255.0, g / 255.0, b / 255.0])
            # pcd = o3d.geometry.PointCloud()
            # pcd.points = o3d.utility.Vector3dVector(points)
            # o3d.io.write_point_cloud("pointcloud_with_color.ply", pcd)

            # xyz = np.array([[0,0,0]])
            # rgb = np.array([[0,0,0]])
            #self.lock.acquire()
            gen = pc2.read_points(pointcloud, skip_nans=True)
            int_data = list(gen)
            xyz = np.empty((len(int_data), 3))
            rgb = np.empty((len(int_data), 3))

            for idx, x in tqdm(enumerate(int_data), desc="Processing point cloud"):
                # test = x[3]
                # # cast float32 to int so that bitwise operations are possible
                # s = struct.pack('>f' ,test)
                # i = struct.unpack('>l',s)[0]
                # # you can get back the float value by the inverse operations
                # pack = ctypes.c_uint32(i).value
                # r = (pack & 0x00FF0000)>> 16
                # g = (pack & 0x0000FF00)>> 8
                # b = (pack & 0x000000FF)
                # # prints r,g,b values in the 0-255 range
                # # x,y,z can be retrieved from the x[0],x[1],x[2]

                rgb_float = x[3]  # RGBA format in float32
                rgb_int = int(rgb_float)
                r = (rgb_int >> 16) & 0x0000ff
                g = (rgb_int >> 8) & 0x0000ff
                b = rgb_int & 0x0000ff

                xyz[idx] = x[:3]
                rgb[idx] = [r, g, b]

            out_pcd = o3d.geometry.PointCloud()
            out_pcd.points = o3d.utility.Vector3dVector(xyz)
            out_pcd.colors = o3d.utility.Vector3dVector(rgb)
            o3d.io.write_point_cloud("pointcloud_with_color.ply", out_pcd)

            rospy.loginfo("PointCloud saved successfully.")

            # サービスコールへのレスポンスを返す
            return TriggerResponse(success=True, message="PointCloud saved successfully.")
        else:
            rospy.logwarn("No PointCloud data received.")
            return TriggerResponse(success=False, message="No PointCloud data received.")

if __name__ == '__main__':
    try:
        # PointCloudSaverのインスタンスを作成
        pointcloud_saver = PointCloudSaver()
        rospy.spin()
    except rospy.ROSInterruptException:
        pass
