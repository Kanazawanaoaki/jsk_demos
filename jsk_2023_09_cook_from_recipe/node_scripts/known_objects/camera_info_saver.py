#!/usr/bin/env python

import rospy
import os
from sensor_msgs.msg import CameraInfo

def camera_info_callback(msg):
    # Extract the camera matrix K
    K = msg.K

    # Format the camera matrix into a string
    cam_K_str = (
        f"{K[0]:.18e} {K[1]:.18e} {K[2]:.18e}\n"
        f"{K[3]:.18e} {K[4]:.18e} {K[5]:.18e}\n"
        f"{K[6]:.18e} {K[7]:.18e} {K[8]:.18e}\n"
    )

    # Write the camera matrix to a file
    save_folder = rospy.get_param('~save_folder', '../../datas/object_datas/images')
    if not os.path.exists(save_folder):
        os.makedirs(save_folder)
    save_filename = os.path.join(save_folder, 'cam_K.txt')
    with open(save_filename, 'w') as file:
        file.write(cam_K_str)

    # Print the camera matrix to the console for verification
    rospy.loginfo(f"Camera matrix K written to cam_K.txt:\n{cam_K_str}")

    # Shutdown the node after saving the file
    rospy.signal_shutdown("Camera matrix saved")

def main():
    # Initialize the ROS node
    rospy.init_node('camera_info_saver', anonymous=True)

    # Get ROS parameters
    cam_info_topic = rospy.get_param('~cam_info', '/camera/color/camera_info')

    # Subscribe to the camera_info topic
    rospy.Subscriber(cam_info_topic, CameraInfo, camera_info_callback)

    # Keep the node running
    rospy.spin()

if __name__ == '__main__':
    main()
