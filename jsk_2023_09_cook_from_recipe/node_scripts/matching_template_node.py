#!/usr/bin/env python
import cv2
import numpy as np
import math

class MatchingTemplate:
    def __init__(self):
        # Initialize any necessary variables or parameters here
        rospy.init_node('matching_template_node', anonymous=True)

        self.subscriber = rospy.Subscriber('~input', Float32MultiArray, self.callback)
        self.publisher = rospy.Publisher('~output', Float32, queue_size=10)

        self.data_buffer = []
        self.window_size = 30
        self.collect_data = False

        # サービスの設定
        self.start_service = rospy.Service('start_moving_average', Empty, self.start_collecting)
        self.stop_service = rospy.Service('stop_moving_average', Empty, self.stop_collecting)

        pass

    def set_template(self, client):
        # Implement template initialization if needed
        pass

    def estimate_od(self, src_img, sourceimg_keypoints, pcam, err_thr, stack_img, ft, o6p):
        # Check if template keypoints and descriptors are initialized
        if not hasattr(self, '_template_keypoints') or not hasattr(self, '_template_descriptors'):
            self.set_template(client)

        if not hasattr(self, '_template_keypoints') or not hasattr(self, '_template_descriptors'):
            print("Template image was not set.")
            return False

        # Stack images
        stack_size = (max(src_img.shape[1], self._template_img.shape[1]), src_img.shape[0] + self._template_img.shape[0])
        stack_img = np.zeros((stack_size[1], stack_size[0], 3), dtype=np.uint8)

        stack_img[:self._template_img.shape[0], :self._template_img.shape[1]] += self._template_img
        stack_img[self._template_img.shape[0]:, :src_img.shape[1]] += src_img

        previous_stack_img = stack_img.copy()

        # Matching
        m_indices, m_dists = ft.knnSearch(self._template_descriptors, 2, params=dict(checks=-1))

        # Matched points
        pt1, pt2 = [], []
        queryIdxs, trainIdxs = [], []
        for j in range(len(self._template_keypoints)):
            if m_dists[j, 0] < m_dists[j, 1] * self._distanceratio_threshold:
                queryIdxs.append(j)
                trainIdxs.append(m_indices[j, 0])

        if not queryIdxs:
            print("Could not find matched points with distanceratio({})".format(self._distanceratio_threshold))
        else:
            pt1 = [self._template_keypoints[j].pt for j in queryIdxs]
            pt2 = [sourceimg_keypoints[j].pt for j in trainIdxs]

        print("Found {} total matches among {} template keypoints".format(len(pt2), len(self._template_keypoints)))

        H, mask = cv2.findHomography(np.float32(pt1), np.float32(pt2), cv2.RANSAC, self._reprojection_threshold)

        # Draw lines
        for j in range(len(pt1)):
            pt_orig = cv2.perspectiveTransform(np.array([pt1[j]], dtype=np.float32), self._affine_matrix)[0, 0]
            if mask[j]:
                cv2.line(stack_img, tuple(pt_orig), tuple(np.array(pt2[j]) + np.array([0, self._template_img.shape[0]])), (0, 255, 0), 1)
            else:
                cv2.line(stack_img, tuple(pt_orig), tuple(np.array(pt2[j]) + np.array([0, self._template_img.shape[0]])), (255, 0, 255), 1)

        inlier_sum = int(np.sum(mask))

        # Additional code for visualization, error calculation, and other tasks

        return inlier_sum > 0  # Modify the return statement based on your requirements

# Example usage:
# matching_template = MatchingTemplate()
# result = matching_template.estimate_od(src_img, sourceimg_keypoints, pcam, err_thr, stack_img, ft, o6p)

if __name__ == '__main__':
    node = MatchingTemplate()
    node.run()


# #### hoge
# import rospy
# from std_msgs.msg import Float32MultiArray, Float32
# from std_srvs.srv import Empty

# class MovingAverageNode:
#     def __init__(self):
#         rospy.init_node('moving_average_node', anonymous=True)

#         self.subscriber = rospy.Subscriber('/pr2_cook_imagebind/recog_result', Float32MultiArray, self.callback)
#         self.publisher = rospy.Publisher('/pr2_cook_imagebind/recog_result/moving_average', Float32, queue_size=10)

#         self.data_buffer = []
#         self.window_size = 30
#         self.collect_data = False

#         # サービスの設定
#         self.start_service = rospy.Service('start_moving_average', Empty, self.start_collecting)
#         self.stop_service = rospy.Service('stop_moving_average', Empty, self.stop_collecting)

#     def callback(self, data):
#         if self.collect_data:
#             self.data_buffer.append(data)

#             if len(self.data_buffer) >= self.window_size:
#                 # 移動平均を計算
#                 moving_average = self.calculate_moving_average()

#                 # パブリッシュ
#                 self.publish_data(moving_average)

#                 # 一番古いデータを削除
#                 self.data_buffer.pop(0)

#     def calculate_moving_average(self):
#         total = sum([value.data[0] for value in self.data_buffer])
#         return total / len(self.data_buffer)

#     def publish_data(self, moving_average):
#         output_msg = Float32(data=moving_average)
#         self.publisher.publish(output_msg)

#     def start_collecting(self, req):
#         rospy.loginfo("Start collecting data.")
#         self.collect_data = True
#         return {}

#     def stop_collecting(self, req):
#         rospy.loginfo("Stop collecting data.")
#         self.collect_data = False
#         # データバッファをリセット
#         self.data_buffer = []
#         return {}

#     def run(self):
#         rospy.spin()

# if __name__ == '__main__':
#     node = MovingAverageNode()
#     node.run()
