#!/usr/bin/env python

import rospy
import tf2_ros
import geometry_msgs.msg
import tf_conversions

def main():
    rospy.init_node('inverse_tf_publisher')

    tfBuffer = tf2_ros.Buffer()
    listener = tf2_ros.TransformListener(tfBuffer)
    broadcaster = tf2_ros.TransformBroadcaster()

    rate = rospy.Rate(10.0)

    parent_frame = 'head_mount_kinect_rgb_optical_frame'
    child_frame = 'r_gripper_tool_frame'
    publish_frame = 'inverse_target_frame'

    while not rospy.is_shutdown():
        try:
            # Get the transformation from tf_frame1 to tf_frame2
            trans = tfBuffer.lookup_transform(parent_frame, child_frame, rospy.Time(0))

            # Convert the transformation to a homogeneous transformation matrix
            transform_matrix = tf_conversions.transformations.quaternion_matrix([
                trans.transform.rotation.x,
                trans.transform.rotation.y,
                trans.transform.rotation.z,
                trans.transform.rotation.w
            ])
            transform_matrix[0, 3] = trans.transform.translation.x
            transform_matrix[1, 3] = trans.transform.translation.y
            transform_matrix[2, 3] = trans.transform.translation.z

            # Compute the inverse transformation matrix
            inverse_transform_matrix = tf_conversions.transformations.inverse_matrix(transform_matrix)

            # Extract the translation and rotation from the inverse transformation matrix
            inverse_translation = inverse_transform_matrix[0:3, 3]
            inverse_rotation = tf_conversions.transformations.quaternion_from_matrix(inverse_transform_matrix)

            # Create the inverse transform message
            inverse_trans = geometry_msgs.msg.TransformStamped()
            inverse_trans.header.stamp = rospy.Time.now()
            inverse_trans.header.frame_id = parent_frame
            inverse_trans.child_frame_id = publish_frame
            inverse_trans.transform.translation.x = inverse_translation[0]
            inverse_trans.transform.translation.y = inverse_translation[1]
            inverse_trans.transform.translation.z = inverse_translation[2]
            inverse_trans.transform.rotation.x = inverse_rotation[0]
            inverse_trans.transform.rotation.y = inverse_rotation[1]
            inverse_trans.transform.rotation.z = inverse_rotation[2]
            inverse_trans.transform.rotation.w = inverse_rotation[3]

            # Publish the inverse transformation
            broadcaster.sendTransform(inverse_trans)

        except (tf2_ros.LookupException, tf2_ros.ConnectivityException, tf2_ros.ExtrapolationException):
            rospy.logwarn("Transform lookup failed")

        rate.sleep()

if __name__ == '__main__':
    main()
