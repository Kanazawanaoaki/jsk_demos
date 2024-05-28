#!/usr/bin/env python

import rospy
import tf2_ros
import yaml
from geometry_msgs.msg import TransformStamped
import rospkg
import os


def load_tf_from_config(config_file, parent_frame, child_frame):
    rospack = rospkg.RosPack()
    package_path = rospack.get_path('jsk_2023_09_cook_from_recipe')
    config_dir_path = os.path.join(package_path, 'datas/tf_configs')
    file_path = os.path.join(config_dir_path, config_file)
    default_file_path = os.path.join(config_dir_path, 'default_tf.yaml')
    if os.path.exists(file_path):
        # ファイルが存在する場合はそのファイルを読み込む
        rospy.loginfo("load tf_config file: {}".format(file_path))
        with open(file_path, 'r') as file:
            config = yaml.safe_load(file)
    else:
        # ファイルが存在しない場合はデフォルトのファイルパスから読み込む
        rospy.loginfo("load tf_config file: {}".format(default_file_path))
        with open(default_file_path, 'r') as file:
            config = yaml.safe_load(file)

    tfs = []
    for tf_name, tf_data in config.items():
        transform = TransformStamped()
        transform.header.frame_id = parent_frame
        transform.child_frame_id = child_frame
        transform.transform.translation.x = tf_data['translation']['x']
        transform.transform.translation.y = tf_data['translation']['y']
        transform.transform.translation.z = tf_data['translation']['z']
        transform.transform.rotation.x = tf_data['rotation']['x']
        transform.transform.rotation.y = tf_data['rotation']['y']
        transform.transform.rotation.z = tf_data['rotation']['z']
        transform.transform.rotation.w = tf_data['rotation']['w']
        tfs.append(transform)

    return tfs

if __name__ == '__main__':
    rospy.init_node('config_tf_broadcaster')

    tf_publisher = tf2_ros.StaticTransformBroadcaster()

    config_file = rospy.get_param('~config_file', 'default_tf.yaml')
    parent_frame = rospy.get_param('~parent_frame', 'map')
    child_frame = rospy.get_param('~child_frame', 'target_object')
    tfs = load_tf_from_config(config_file, parent_frame, child_frame)

    rate = rospy.Rate(1) # Publish rate is 1 Hz

    while not rospy.is_shutdown():
        for tf in tfs:
            tf.header.stamp = rospy.Time.now()
            tf_publisher.sendTransform(tf)
        rate.sleep()
