#!/usr/bin/env python

import rospy
import tf2_ros
from geometry_msgs.msg import TransformStamped
from jsk_recognition_msgs.msg import ICPResult

def icp_callback(msg, score_min_thre=0.0000001, score_max_thre=100):
    # ICP結果からTransformを生成
    transform = TransformStamped()
    transform.header = msg.header
    transform.child_frame_id = "icp_result_frame"
    transform.transform.translation = msg.pose.position
    transform.transform.rotation = msg.pose.orientation

    # TFをブロードキャスト
    if msg.score >= score_min_thre and msg.score <= score_max_thre:
        tf_broadcaster.sendTransform(transform)
        rospy.loginfo("Broadcasted icp_result TF, icp score is to {}".format(msg.score))

if __name__ == "__main__":
    rospy.init_node('icp_tf_publisher')
    tf_broadcaster = tf2_ros.TransformBroadcaster()
    rospy.Subscriber('/icp_registration/icp_result', ICPResult, icp_callback)
    rospy.spin()
