#!/usr/bin/env python

import argparse
import cv2

from pathlib import Path
import argparse
import random
import numpy as np
import matplotlib.cm as cm
import torch

from models.matching import Matching
from models.utils import (compute_pose_error, compute_epipolar_error,
                          estimate_pose, make_matching_plot,
                          error_colormap, AverageTimer, pose_auc, read_image,
                          rotate_intrinsics, rotate_pose_inplane,
                          scale_intrinsics)

import rospy
from message_filters import ApproximateTimeSynchronizer, Subscriber
from std_srvs.srv import Trigger, TriggerResponse
from jsk_recognition_msgs.srv import TransformScreenpoint
from geometry_msgs.msg import PointStamped
from sensor_msgs.msg import Image, CameraInfo
from cv_bridge import CvBridge

from jsk_2023_09_cook_from_recipe.srv import CalcPnp, CalcPnpResponse
import tf

torch.set_grad_enabled(False)


class PnpPoseEstimaterNode:
    def __init__(self):
        rospy.init_node('pnp_pose_estimate')

        rospy.Subscriber("/pointcloud_screenpoint_nodelet/output_point", PointStamped, self.point_callback) ## Must be subscribe to use point_screeenpoint

        # パラメータの設定
        self.top_k_num = 50
        self.original_image_path='/home/kanazawa/Desktop/data/tmp/pr2-head-rgbd-images/1692882437486995277/pr2_rgb_image_rect_color_request.png' # Path to the original location image

        self.rot0, self.rot1 = 0, 0

        self.nms_radius = 4 ## SuperPoint Non Maximum Suppression (NMS) radius (Must be positive)
        self.keypoint_threshold = 0.005 ## SuperPoint keypoint detector confidence threshold
        self.max_keypoints = 1024 ## Maximum number of keypoints detected by Superpoint (\'-1\' keeps all keypoints)
        self.superglue = "indoor" ## SuperGlue weights choices={'indoor', 'outdoor'}
        self.sinkhorn_iterations = 20 ## Number of Sinkhorn iterations performed by SuperGlue
        self.match_threshold = 0.2 ## SuperGlue match threshold

        self.resize = [640, 480] ## Resize the input image before running inference. If two numbers, resize to the exact dimensions, if one number, resize the max dimension, if -1, do not resize
        self.resize_float = False ## Resize the image after casting uint8 to float

        self.image_topic = "/kinect_head/rgb/image_rect_color"
        self.camera_info_topic = "/kinect_head/rgb/camera_info"
        self.bridge = CvBridge()
        self.match_image_pub = rospy.Publisher("/match_image_topic", Image, queue_size=1)

        self.image = None
        self.camera_info = None
        self.data_update_flag = True
        self.camera_matrix = np.array([[525.0, 0.0, 319.5],
                                       [0.0, 525.0, 239.5],
                                       [0.0, 0.0, 1.0]], dtype=float)
        self.dist_coeffs = np.array([0, 0, 0, 0, 0])

        # メッセージフィルタリングのためのサブスクライバーを設定
        image_sub = Subscriber(self.image_topic, Image)
        camera_info_sub = Subscriber(self.camera_info_topic, CameraInfo)
        self.message_filter = ApproximateTimeSynchronizer([image_sub, camera_info_sub], queue_size=5, slop=0.1)
        self.message_filter.registerCallback(self.message_callback)

        self.service = rospy.Service("calc_pnp_with_superglue", CalcPnp, self.service_callback)

    def opencv_rotation_matrix_to_quaternion(self, rotation_matrix):
        # OpenCVの回転行列をtf2のクォータニオンに変換
        quat = tf.transformations.quaternion_from_matrix(rotation_matrix) ## TODo
        return quat

    def message_callback(self, image_msg, camera_info_msg):
        if self.data_update_flag:
            self.image = self.bridge.imgmsg_to_cv2(image_msg, desired_encoding="passthrough")
            self.camera_info = camera_info_msg
            self.camera_matrix = np.array(self.camera_info.K, dtype=float).reshape(3, 3)
            self.dist_coeffs = np.array(self.camera_info.D)

    def service_callback(self, request):
        if self.image is None or self.camera_info is None:
            return CalcPnpResponse(success=False)

        self.data_update_flag = False
        mkpts0, mkpts1, mconf = self.match_with_superglue()
        rotation_matrix, tvec = self.calc_pnp(mkpts0, mkpts1, mconf)

        # quat = self.opencv_rotation_matrix_to_quaternion(rotation_matrix)

        self.data_update_flag = True
        return CalcPnpResponse(success=True, rotation_matrix=rotation_matrix.reshape(9).tolist(), position_vector=tvec)

    def point_callback(self, msg):
        point_msg = msg
        # do nothing just listen

    def call_screenpoint_service(self, x, y):
        pointcloud_screenpoint_service = '/pointcloud_screenpoint_nodelet/screen_to_point'
        rospy.wait_for_service(pointcloud_screenpoint_service)

        try:
            screenpoint_service = rospy.ServiceProxy(pointcloud_screenpoint_service, TransformScreenpoint)
            response = screenpoint_service(x, y, False)
            return response.point
        except rospy.ServiceException as e:
            print("Service call failed:", str(e))
            return None

    def match_with_superglue(self):
        torch.set_grad_enabled(False)

        # K0 = self.camera_matrix
        # K1 = self.camera_matrix

        # Load the SuperPoint and SuperGlue models.
        device = 'cuda' if torch.cuda.is_available() else 'cpu'
        print('Running inference on device \"{}\"'.format(device))
        config = {
            'superpoint': {
                'nms_radius': self.nms_radius,
                'keypoint_threshold': self.keypoint_threshold,
                'max_keypoints': self.max_keypoints
            },
            'superglue': {
                'weights': self.superglue,
                'sinkhorn_iterations': self.sinkhorn_iterations,
                'match_threshold': self.match_threshold,
            }
        }
        matching = Matching(config).eval().to(device)

        # Load the image pair.
        image0, inp0, scales0 = read_image(
            self.original_image_path, device, self.resize, self.rot0, self.resize_float)
        gray_image = cv2.cvtColor(self.image, cv2.COLOR_BGR2GRAY)
        image1, inp1, scales1 = read_image(None, device, self.resize, self.rot1, self.resize_float, gray_image)
        if image0 is None or image1 is None:
            print('Problem reading image from: {} or {}'.format(
                self.original_image_path, "ROS Image"))
            exit(1)

        # Perform the matching.
        pred = matching({'image0': inp0, 'image1': inp1})
        pred = {k: v[0].cpu().numpy() for k, v in pred.items()}
        kpts0, kpts1 = pred['keypoints0'], pred['keypoints1']
        matches, conf = pred['matches0'], pred['matching_scores0']

        # Keep the matching keypoints.
        valid = matches > -1
        mkpts0 = kpts0[valid]
        mkpts1 = kpts1[matches[valid]]
        mconf = conf[valid]
        print(len(mkpts0))

        # TODO publish match iamges and not save
        viz_path = "output/matches.png"
        # Visualize the matches.
        color = cm.jet(mconf)
        text = [
            'SuperGlue',
            'Keypoints: {}:{}'.format(len(kpts0), len(kpts1)),
            'Matches: {}'.format(len(mkpts0)),
        ]
        if self.rot0 != 0 or self.rot1 != 0:
            text.append('Rotation: {}:{}'.format(rot0, rot1))

        # Display extra parameter info.
        k_thresh = matching.superpoint.config['keypoint_threshold']
        m_thresh = matching.superglue.config['match_threshold']
        small_text = [
            'Keypoint Threshold: {:.4f}'.format(k_thresh),
            'Match Threshold: {:.2f}'.format(m_thresh),
            # 'Image Pair: {}:{}'.format(stem0, stem1),
        ]

        match_result = make_matching_plot(image0, image1, kpts0, kpts1, mkpts0, mkpts1, color,
                                          text, None, show_keypoints=True,
                                          fast_viz=True, opencv_display=False,
                                          opencv_title='Matches', small_text=small_text,
                                          save_flag=False)
        match_image_msg = self.bridge.cv2_to_imgmsg(match_result, encoding="rgb8")
        self.match_image_pub.publish(match_image_msg)
        return mkpts0, mkpts1, mconf

    def calc_pnp(self, mkpts0, mkpts1, mconf):
        # K0 = self.camera_matrix
        # K1 = self.camera_matrix
        # # Scale the intrinsics to resized image.
        # K0 = scale_intrinsics(K0, scales0)
        # K1 = scale_intrinsics(K1, scales1)

        sorted_data = sorted(zip(mkpts0, mkpts1, mconf), key=lambda x: x[2],
                             reverse=True)[:self.top_k_num]
        sorted_mkpts0, sorted_mkpts1, sorted_mconf = zip(*sorted_data)
        sorted_mkpts0 = np.array(sorted_mkpts0)
        sorted_mkpts1 = np.array(sorted_mkpts1)
        sorted_mconf = np.array(sorted_mconf)

        original_img_points = sorted_mkpts0.tolist()
        current_img_points = sorted_mkpts1.tolist()
        print("original points")
        print(original_img_points)
        print("current points")
        print(current_img_points)

        ## PnP法をする

        # point screenpointで現在の3次元座標を取得
        screenpoint_results = []
        for x, y in current_img_points:
            point = self.call_screenpoint_service(x, y)
            if point:
                screenpoint_results.append([point.x, point.y, point.z])

        print(screenpoint_results)

        # PnP法の計算
        image_points = np.array(original_img_points)
        object_points = np.array(screenpoint_results)

        retval, rvec, tvec = cv2.solvePnP(object_points, image_points, self.camera_matrix, self.dist_coeffs)
        rotation_matrix, _ = cv2.Rodrigues(rvec)

        print("回転行列:")
        print(rotation_matrix)
        print("平行移動ベクトル:")
        print(tvec)
        return rotation_matrix, tvec

    def run(self):
        rospy.spin()

if __name__ == '__main__':
    node = PnpPoseEstimaterNode()
    node.run()

    # コマンドライン引数の設定
    parser = argparse.ArgumentParser(description='Load and display two images.')
    # parser.add_argument('--original_image_dir', '-i1',type=str, default='/home/kanazawa/Desktop/data/tmp/pr2-head-rgbd-images/1692882437486995277', help='Path to the first image')

    # parser.add_argument('--image_dir2', '-i2',type=str, default='/home/kanazawa/Desktop/data/tmp/pr2-head-rgbd-images/1692939457371177180', help='Path to the second image')

    # parser.add_argument(
    #     '--superglue', choices={'indoor', 'outdoor'}, default='indoor',
    #     help='SuperGlue weights')
    # parser.add_argument(
    #     '--max_keypoints', type=int, default=1024,
    #     help='Maximum number of keypoints detected by Superpoint'
    #          ' (\'-1\' keeps all keypoints)')
    # parser.add_argument(
    #     '--keypoint_threshold', type=float, default=0.005,
    #     help='SuperPoint keypoint detector confidence threshold')
    # parser.add_argument(
    #     '--nms_radius', type=int, default=4,
    #     help='SuperPoint Non Maximum Suppression (NMS) radius'
    #     ' (Must be positive)')
    # parser.add_argument(
    #     '--sinkhorn_iterations', type=int, default=20,
    #     help='Number of Sinkhorn iterations performed by SuperGlue')
    # parser.add_argument(
    #     '--match_threshold', type=float, default=0.2,
    #     help='SuperGlue match threshold')


    # parser.add_argument(
    #     '--resize', type=int, nargs='+', default=[640, 480],
    #     help='Resize the input image before running inference. If two numbers, '
    #          'resize to the exact dimensions, if one number, resize the max '
    #          'dimension, if -1, do not resize')
    # parser.add_argument(
    #     '--resize_float', action='store_true',
    #     help='Resize the image after casting uint8 to float')

    # parser.add_argument(
    #     '--fast_viz', action='store_true',
    #     help='Use faster image visualization with OpenCV instead of Matplotlib')
    # parser.add_argument(
    #     '--show_keypoints', action='store_true',
    #     help='Plot the keypoints in addition to the matches')
    # parser.add_argument(
    #     '--opencv_display', action='store_true',
    #     help='Visualize via OpenCV before saving output images')

    # args = parser.parse_args()





