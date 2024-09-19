#!/usr/bin/env python

import rospy
import message_filters
from sensor_msgs.msg import Image
from cv_bridge import CvBridge
import cv2
import os
import time
from std_srvs.srv import Empty, EmptyResponse

# Global variable to control the start/stop state
is_running = False

def callback(rgb_msg, depth_msg):
    global is_running
    if not is_running:
        return

    bridge = CvBridge()

    # Convert ROS Image messages to OpenCV images
    rgb_image = bridge.imgmsg_to_cv2(rgb_msg, desired_encoding='bgr8')
    depth_image = bridge.imgmsg_to_cv2(depth_msg, desired_encoding='passthrough')

    # Get the current time as UNIX timestamp for filename
    current_time = str(int(time.time() * 1000))  # Convert to milliseconds and convert to string

    # Get the specified folder from ROS parameters
    specified_folder = rospy.get_param('~specified_folder', '../../datas/object_datas/images')

    # Create directories if they don't exist
    rgb_folder = os.path.join(specified_folder, 'rgb')
    depth_folder = os.path.join(specified_folder, 'depth')
    if not os.path.exists(rgb_folder):
        os.makedirs(rgb_folder)
    if not os.path.exists(depth_folder):
        os.makedirs(depth_folder)

    # Save images with timestamped filenames
    rgb_filename = os.path.join(rgb_folder, f'{current_time}.png')
    depth_filename = os.path.join(depth_folder, f'{current_time}.png')

    cv2.imwrite(rgb_filename, rgb_image)
    cv2.imwrite(depth_filename, depth_image)

    rospy.loginfo(f'Saved RGB image: {rgb_filename}')
    rospy.loginfo(f'Saved Depth image: {depth_filename}')

def start_service(req):
    global is_running
    is_running = True
    rospy.loginfo("Image synchronization started.")
    return EmptyResponse()

def stop_service(req):
    global is_running
    is_running = False
    rospy.loginfo("Image synchronization stopped.")
    return EmptyResponse()

def main():
    rospy.init_node('rgb_and_depth_saver', anonymous=True)

    # Define the topics to subscribe to
    rgb_topic = '/camera_remote/rgb/image_raw'
    depth_topic = '/camera_remote/aligned_depth_to_color/image_raw'

    # Create subscribers
    rgb_sub = message_filters.Subscriber(rgb_topic, Image)
    depth_sub = message_filters.Subscriber(depth_topic, Image)

    # Synchronize the topics
    ts = message_filters.TimeSynchronizer([rgb_sub, depth_sub], 10)
    ts.registerCallback(callback)

    # Define the start and stop services
    start_srv = rospy.Service('~start_sync', Empty, start_service)
    stop_srv = rospy.Service('~stop_sync', Empty, stop_service)

    rospy.loginfo("Ready to start and stop image synchronization.")
    rospy.spin()

if __name__ == '__main__':
    main()
