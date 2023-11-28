#!/usr/bin/env python

from pathlib import Path

import os.path as osp
import actionlib
import numpy as np
import rospy
import trimesh
from pybsc import current_time_str, makedirs
from pybsc.image_utils import imwrite
from r8_5_interface import R85, R85ROSRobotInterface
from ros_speak import speak_jp
from scipy.spatial.distance import cdist
from skrobot.coordinates import Coordinates
from skrobot.coordinates.math import (angle_between_vectors,
                                      rotation_matrix_from_axis)
from skrobot.model import Axis, MeshLink
from skrobot.viewers import TrimeshSceneViewer

from jsk_teaching_object.msg import (TakeActionAction, TakeActionResult,
                                     TakeImagePhotoAction,
                                     TakeImagePhotoResult)
from jsk_teaching_object.topic_subscriber import ImageSubscriber


def find_best_order(angles):
    n = len(angles)
    distance_matrix = cdist(angles, angles, 'sqeuclidean')
    np.fill_diagonal(distance_matrix, float('inf'))

    best_order = None
    min_sq_sum = float('inf')

    for start_idx in range(n):
        remaining_indices = set(range(n)) - {start_idx}
        current_order = [start_idx]

        while remaining_indices:
            last_idx = current_order[-1]
            next_idx = min(remaining_indices, key=lambda idx: distance_matrix[last_idx, idx])
            current_order.append(next_idx)
            remaining_indices.remove(next_idx)

        sq_sum = sum(distance_matrix[current_order[i], current_order[i+1]] for i in range(n-1))
        if sq_sum < min_sq_sum:
            min_sq_sum = sq_sum
            best_order = [angles[idx] for idx in current_order]

    return best_order, min_sq_sum


class LookObject(object):

    def __init__(self, debug=False):
        self.debug = debug
        r = R85()
        ri = R85ROSRobotInterface(r)
        r.angle_vector(ri.angle_vector())

        self.r = r
        self.ri = ri
        self.end_coords_axis = Axis.from_coords(r.rarm_end_coords)
        self.object_center_coords = Axis()
        if self.debug:
            v = TrimeshSceneViewer()
            v.add(self.r)
            v.add(self.end_coords_axis)
            v.add(self.object_center_coords)
            v.show()
            self.v = v

        self.take_image_photo_server = actionlib.SimpleActionServer(
            '~take_image_photo',
            TakeImagePhotoAction,
            execute_cb=self.take_image_photo_action,
            auto_start=True)
        rospy.loginfo('take image photo action server started.')

        self.take_action_server = actionlib.SimpleActionServer(
            '~take_action',
            TakeActionAction,
            execute_cb=self.detection_pose,
            auto_start=True)
        rospy.loginfo('take action action server started.')

        self.cached_ik = rospy.get_param('~cached_ik', True)
        rospy.loginfo('Cached ik is {}.'.format(
            'enabled' if self.cached_ik else 'disabled'))

    def speak_jp(self, *args, **kwargs):
        # return speak_jp(*args, **kwargs)
        pass

    def take_image_photo_action(self, goal):
        self.look(topic_name=goal.image_topic_name,
                  save_path=goal.save_path)
        self.take_image_photo_server.set_succeeded(TakeImagePhotoResult())

    def look(self, topic_name=None, save_path=None):
        if topic_name is not None and save_path is not None:
            makedirs(save_path)
            sub = ImageSubscriber(topic_name)
        r = self.r
        ri = self.ri
        if self.debug:
            v = self.v

        r.reset_pose()
        r.r_zaxis_joint.joint_angle(relative=0.3)
        r.l_zaxis_joint.joint_angle(0.1)
        ri.angle_vector(r.angle_vector(), 5)
        ri.zmove_client(r.r_zaxis_joint.joint_angle(),
                        r.l_zaxis_joint.joint_angle(),
                        5.0)
        self.speak_jp('画像を撮影するために見回します。', wait=False)

        radius = 0.2
        m = trimesh.creation.icosphere(subdivisions=2, radius=radius)
        sphere = MeshLink(m)
        sphere.translate((-0.5, -0.4, 0.8))
        self.object_center_coords.newcoords(sphere.copy_worldcoords())

        avs = []
        for i in range(len(m.vertices)):
            sphere_center = Coordinates(
                sphere.copy_worldcoords().transform_vector(m.centroid))
            surface_point = Coordinates(
                pos=sphere.copy_worldcoords().transform_vector(m.vertices[i]))

            if sphere_center.worldpos()[2] + radius / 2.0 >= surface_point.worldpos()[2]:
                continue
            angle = angle_between_vectors(sphere_center.worldpos() - surface_point.worldpos(),
                                          [0, 1, 0], directed=False)
            second_axis = (0, 1, 0)
            if angle < np.deg2rad(0.01):
                second_axis = (0, 0, 1)
            x_direction = rotation_matrix_from_axis(
                sphere_center.worldpos() - surface_point.worldpos(),
                second_axis,
                axes='xy')
            r.reset_pose()
            r.l_zaxis_joint.joint_angle(0.1)
            r.r_zaxis_joint.joint_angle(1.3)
            ret = r.rarm.inverse_kinematics(
                Coordinates(pos=surface_point.worldpos(),
                            rot=x_direction),
                rotation_axis='x',
                translation_axis=True,
                thre=100,
                stop=500,
                move_target=r.rarm_hand_camera_end_coords)
            if ret is not False:
                r.r_finger_upper_joint.joint_angle(-np.pi / 2.0)
                avs.append((r.angle_vector(),
                            surface_point.worldpos()))

        avs = sorted(avs, key=lambda item: (item[1][0], item[1][1]))
        av_onlys = [av[0] for av in avs]
        cache_path = '/home/leus/cached_ik.npy'
        if self.cached_ik and osp.exists(cache_path):
            rospy.loginfo('Load cached ik from {}'.format(cache_path))
            avs = np.load(cache_path)
        else:
            avs = find_best_order(av_onlys)[0]
            np.save(cache_path, avs)
            rospy.loginfo('Save cached ik to {}'.format(cache_path))
        for av in avs:
            r.angle_vector(av)
            if self.debug:
                v.redraw()
            fastest_time = ri.angle_vector_duration(
                ri.angle_vector(),
                r.angle_vector(),
                controller_type=None)
            fastest_time = max(fastest_time, 1.0)
            rospy.loginfo('Send angle vector {} sec'.format(fastest_time))
            ri.angle_vector(r.angle_vector(), fastest_time)
            ri.zmove_client(r.r_zaxis_joint.joint_angle(),
                            r.l_zaxis_joint.joint_angle(),
                            fastest_time)
            ri.wait_interpolation()
            rospy.sleep(2.0)
            if topic_name is not None and save_path is not None:
                self.speak_jp('package://rostwitter/resource/camera.wav', wait=False)
                img = sub.take_image()
                imwrite(
                    Path(save_path) / '{}.jpg'.format(current_time_str()),
                    img)
        if topic_name is not None and save_path is not None:
            del sub

        self.speak_jp('画像を撮影し終わりました。', wait=True)
        self.speak_jp('初期姿勢に戻ります。', wait=False)

        r.reset_pose()
        fastest_time = ri.angle_vector_duration(
            ri.angle_vector(),
            r.angle_vector(),
            controller_type=None)
        rospy.loginfo('Send angle vector {} sec'.format(fastest_time))
        ri.angle_vector(r.angle_vector(), fastest_time)
        ri.zmove_client(r.r_zaxis_joint.joint_angle(),
                        r.l_zaxis_joint.joint_angle(),
                        fastest_time)

    def detection_pose(self, goal):
        ri = self.ri
        r = self.r
        r.reset_pose()
        r.r_zaxis_joint.joint_angle(1.4)
        r.r_shoulder_y_joint.joint_angle(np.pi / 2.0)

        r.l_zaxis_joint.joint_angle(1.18)
        r.l_shoulder_y_joint.joint_angle(0.75)
        r.l_elbow_p1_joint.joint_angle(0.4)
        r.l_elbow_p2_joint.joint_angle(0.4)
        r.l_upper_arm_y_joint.joint_angle(0.0)
        r.l_wrist_y_joint.joint_angle(0.0)
        r.l_wrist_r_joint.joint_angle(np.pi / 2.0)
        r.l_wrist_p_joint.joint_angle(0.0)

        fastest_time = ri.angle_vector_duration(
            ri.angle_vector(),
            r.angle_vector(),
            controller_type=None)
        rospy.loginfo('Send angle vector {} sec'.format(fastest_time))
        ri.angle_vector(r.angle_vector(), fastest_time)
        ri.zmove_client(r.r_zaxis_joint.joint_angle(),
                        r.l_zaxis_joint.joint_angle(),
                        fastest_time)
        ri.wait_interpolation()

        self.take_image_photo_server.set_succeeded(
            TakeActionResult())


if __name__ == '__main__':
    rospy.init_node('r8_5_look_server')
    act = LookObject()  # NOQA
    rospy.spin()
