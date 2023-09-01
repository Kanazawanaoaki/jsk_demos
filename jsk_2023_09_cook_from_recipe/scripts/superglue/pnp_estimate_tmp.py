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

torch.set_grad_enabled(False)


if __name__ == '__main__':
    # コマンドライン引数の設定
    parser = argparse.ArgumentParser(description='Load and display two images.')
    parser.add_argument('--image_dir1', '-i1',type=str, default='/home/kanazawa/Desktop/data/tmp/pr2-head-rgbd-images/1692882437486995277', help='Path to the first image')
    parser.add_argument('--image_dir2', '-i2',type=str, default='/home/kanazawa/Desktop/data/tmp/pr2-head-rgbd-images/1692882456791283363', help='Path to the second image')

    parser.add_argument(
        '--superglue', choices={'indoor', 'outdoor'}, default='indoor',
        help='SuperGlue weights')
    parser.add_argument(
        '--max_keypoints', type=int, default=1024,
        help='Maximum number of keypoints detected by Superpoint'
             ' (\'-1\' keeps all keypoints)')
    parser.add_argument(
        '--keypoint_threshold', type=float, default=0.005,
        help='SuperPoint keypoint detector confidence threshold')
    parser.add_argument(
        '--nms_radius', type=int, default=4,
        help='SuperPoint Non Maximum Suppression (NMS) radius'
        ' (Must be positive)')
    parser.add_argument(
        '--sinkhorn_iterations', type=int, default=20,
        help='Number of Sinkhorn iterations performed by SuperGlue')
    parser.add_argument(
        '--match_threshold', type=float, default=0.2,
        help='SuperGlue match threshold')


    parser.add_argument(
        '--resize', type=int, nargs='+', default=[640, 480],
        help='Resize the input image before running inference. If two numbers, '
             'resize to the exact dimensions, if one number, resize the max '
             'dimension, if -1, do not resize')
    parser.add_argument(
        '--resize_float', action='store_true',
        help='Resize the image after casting uint8 to float')

    parser.add_argument(
        '--fast_viz', action='store_true',
        help='Use faster image visualization with OpenCV instead of Matplotlib')
    parser.add_argument(
        '--show_keypoints', action='store_true',
        help='Plot the keypoints in addition to the matches')
    parser.add_argument(
        '--opencv_display', action='store_true',
        help='Visualize via OpenCV before saving output images')

    args = parser.parse_args()

    viz_path = "output/matches.png"

    ## パラメータの設定
    rot0, rot1 = 0, 0
    camera_matrix = np.array([[525.0, 0.0, 319.5],
                              [0.0, 525.0, 239.5],
                              [0.0, 0.0, 1.0]], dtype=float)
    # camera_matrix = np.array([[1217.935302734375, 0.0, 1279.5836181640625],
    #                           [0.0, 1217.711669921875, 738.4121704101562],
    #                           [0.0, 0.0, 1.0]], dtype=float)

    K0 = camera_matrix
    K1 = camera_matrix

    nms_radius = args.nms_radius
    keypoint_threshold = args.keypoint_threshold
    max_keypoints = args.max_keypoints
    superglue = args.superglue
    sinkhorn_iterations = args.sinkhorn_iterations
    match_threshold = args.match_threshold

    # 画像の読み込み
    # image1 = cv2.imread(args.image_path1)
    # image2 = cv2.imread(args.image_path2)
    # # 読み込んだ画像の表示
    # cv2.imshow('Image 1', image1)
    # cv2.imshow('Image 2', image2)
    # cv2.waitKey(0)
    # cv2.destroyAllWindows()

    # Load the SuperPoint and SuperGlue models.
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    print('Running inference on device \"{}\"'.format(device))
    config = {
        'superpoint': {
            'nms_radius': nms_radius,
            'keypoint_threshold': keypoint_threshold,
            'max_keypoints': max_keypoints
        },
        'superglue': {
            'weights': superglue,
            'sinkhorn_iterations': sinkhorn_iterations,
            'match_threshold': match_threshold,
        }
    }
    matching = Matching(config).eval().to(device)

    # Load the image pair.
    image0, inp0, scales0 = read_image(
        args.image_dir1 +  "/pr2_rgb_image_rect_color_request.png", device, args.resize, rot0, args.resize_float)
    image1, inp1, scales1 = read_image(
        args.image_dir2 + "/pr2_rgb_image_rect_color_request.png", device, args.resize, rot1, args.resize_float)
    if image0 is None or image1 is None:
        print('Problem reading image pair: {} {}'.format(
            args.image_path1, args.image_path2))
        exit(1)

    # import ipdb
    # ipdb.set_trace()

    # Perform the matching.
    pred = matching({'image0': inp0, 'image1': inp1})
    pred = {k: v[0].cpu().numpy() for k, v in pred.items()}
    kpts0, kpts1 = pred['keypoints0'], pred['keypoints1']
    matches, conf = pred['matches0'], pred['matching_scores0']
    # Write the matches to disk.
    out_matches = {'keypoints0': kpts0, 'keypoints1': kpts1,
                   'matches': matches, 'match_confidence': conf}

    # Keep the matching keypoints.
    valid = matches > -1
    mkpts0 = kpts0[valid]
    mkpts1 = kpts1[matches[valid]]
    mconf = conf[valid]
    print(mkpts0)

    # Visualize the matches.
    color = cm.jet(mconf)
    text = [
        'SuperGlue',
        'Keypoints: {}:{}'.format(len(kpts0), len(kpts1)),
        'Matches: {}'.format(len(mkpts0)),
    ]
    if rot0 != 0 or rot1 != 0:
        text.append('Rotation: {}:{}'.format(rot0, rot1))

    # Display extra parameter info.
    k_thresh = matching.superpoint.config['keypoint_threshold']
    m_thresh = matching.superglue.config['match_threshold']
    small_text = [
        'Keypoint Threshold: {:.4f}'.format(k_thresh),
        'Match Threshold: {:.2f}'.format(m_thresh),
        # 'Image Pair: {}:{}'.format(stem0, stem1),
    ]

    make_matching_plot(
        image0, image1, kpts0, kpts1, mkpts0, mkpts1, color,
        text, viz_path, args.show_keypoints,
        args.fast_viz, args.opencv_display, 'Matches', small_text)


    # Scale the intrinsics to resized image.
    K0 = scale_intrinsics(K0, scales0)
    K1 = scale_intrinsics(K1, scales1)

    # sorted_data = sorted(zip(mkpts0, mkpts1, mconf), key=lambda x: x[2],
    #                      reverse=True)[:50]
    sorted_data = sorted(zip(mkpts0, mkpts1, mconf), key=lambda x: x[2],
                         reverse=True)[:10]
    sorted_mkpts0, sorted_mkpts1, sorted_mconf = zip(*sorted_data)
    sorted_mkpts0 = np.array(sorted_mkpts0)
    sorted_mkpts1 = np.array(sorted_mkpts1)
    sorted_mconf = np.array(sorted_mconf)

    # for ii,j,k in zip(sorted_mkpts0, sorted_mkpts1, sorted_mconf):
    #     print(ii,j,k)

    print("original points")
    print(sorted_mkpts0.tolist())
    print("now points")
    print(sorted_mkpts1.tolist())

    # import ipdb
    # ipdb.set_trace()

    # fundamental_matrix, _ = cv2.findFundamentalMat(sorted_mkpts0, sorted_mkpts1, method=cv2.FM_RANSAC)
    fundamental_matrix, _ = cv2.findFundamentalMat(sorted_mkpts0, sorted_mkpts1, method=cv2.FM_8POINT)
    retval, rotation, translation, mask = cv2.recoverPose(fundamental_matrix, sorted_mkpts0, sorted_mkpts1, cameraMatrix=K0)

    print(rotation)
    print(translation)


    # エピポーラ線を計算
    epilines1 = cv2.computeCorrespondEpilines(sorted_mkpts1.reshape(-1, 1, 2), 2, fundamental_matrix)
    epilines1 = epilines1.reshape(-1, 3)

    # エピポーラ線が描かれた画像を表示
    H0, W0 = image0.shape
    out0 = 255*np.ones((H0, W0), np.uint8)
    out0[:H0, :W0] = image0
    out0 = np.stack([out0]*3, -1)
    H1, W1 = image1.shape
    out1 = 255*np.ones((H1, W1), np.uint8)
    out1[:H1, :W1] = image1
    out1 = np.stack([out1]*3, -1)

    # 赤色の点のBGR値
    red_color = (0, 0, 255)

    # 画像に点を描画
    for coord in sorted_mkpts0:
        # import ipdb
        # ipdb.set_trace()
        cv2.circle(out0, tuple(coord), 5, red_color, -1)  # -1 は塗りつぶし

    for coord in sorted_mkpts1:
        cv2.circle(out1, tuple(coord), 5, red_color, -1)

    # cv2.imshow('Image 0 with Epilines', out0)
    # cv2.imshow('Image 1 with Epilines', out1)
    # cv2.waitKey(0)
    # cv2.destroyAllWindows()

    # 画像1にエピポーラ線を描画
    for line in epilines1:
        x0, y0 = map(int, [0, -line[2] / line[1]])
        x1, y1 = map(int, [out0.shape[1], -(line[2] + line[0] * out0.shape[1]) / line[1]])
        cv2.line(out0, (x0, y0), (x1, y1), (0, 255, 0), 1)

    # 画像2にエピポーラ線を描画
    epilines2 = cv2.computeCorrespondEpilines(sorted_mkpts0.reshape(-1, 1, 2), 1, fundamental_matrix)
    epilines2 = epilines2.reshape(-1, 3)
    for line in epilines2:
        x0, y0 = map(int, [0, -line[2] / line[1]])
        x1, y1 = map(int, [out1.shape[1], -(line[2] + line[0] * out1.shape[1]) / line[1]])
        cv2.line(out1, (x0, y0), (x1, y1), (0, 255, 0), 1)

    # エピポーラ線が描かれた画像を表示
    cv2.imshow('Out 0 with Epilines', out0)
    cv2.imshow('Out 1 with Epilines', out1)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

    # import ipdb
    # ipdb.set_trace()

    ## PNP法をする
    depth_path = args.image_dir1 +  "/pr2_depth_image_rect_request.pkl"

    import pickle
    import numpy as np
    import matplotlib.pyplot as plt

    with open(depth_path, 'rb') as f:
        depth_data = pickle.load(f)

    # 深度データをNumPy配列に変換
    depth_array = np.array(depth_data)

    # 深度画像の描画
    plt.imshow(depth_array, cmap='jet')
    plt.colorbar()
    plt.show()

    image_points = []
    object_points = []
    for idx, point in enumerate(sorted_mkpts0):
        print(point)
        if not np.isnan(depth_array[int(point[1])][int(point[0])]):
            im_point = np.array([sorted_mkpts1[idx][1], sorted_mkpts1[idx][0]])
            image_points.append(im_point)
            depth = depth_array[int(point[1])][int(point[0])]
            depth = depth * 100.0
            coord = np.array([point[1], point[0], depth])
            print(depth)
            object_points.append(coord)
            print(sorted_mkpts1[idx], coord)

    # 歪み係数（カメラキャリブレーション結果から）
    dist_coeffs = np.array([0, 0, 0, 0, 0])

    # import ipdb
    # ipdb.set_trace()
    object_points = np.array(object_points)
    image_points = np.array(image_points)
    # PnP法で外部パラメータ（回転行列と平行移動ベクトル）を計算
    retval, rvec, tvec = cv2.solvePnP(object_points, image_points, camera_matrix, dist_coeffs)

    # 回転ベクトルを回転行列に変換
    rotation_matrix, _ = cv2.Rodrigues(rvec)

    print("回転行列:")
    print(rotation_matrix)
    print("平行移動ベクトル:")
    print(tvec)
