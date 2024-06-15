import argparse
import rosbag
import cv2
from cv_bridge import CvBridge
import numpy as np
import rospy
import os

def process_comp_depth_image(msg):
    # 'msg' as type CompressedImage
    depth_fmt, compr_type = msg.format.split(';')
    # remove white space
    depth_fmt = depth_fmt.strip()
    compr_type = compr_type.strip()
    # import ipdb
    # ipdb.set_trace()
    # if compr_type != "compressedDepth":
    if compr_type != "compressedDepth png":
        raise Exception("Compression type is not 'compressedDepth'."
                        "You probably subscribed to the wrong topic.")

    # remove header from raw data
    depth_header_size = 12
    raw_data = msg.data[depth_header_size:]

    # depth_img_raw = cv2.imdecode(np.fromstring(raw_data, np.uint8), cv2.CV_LOAD_IMAGE_UNCHANGED)
    depth_img_raw = cv2.imdecode(np.fromstring(raw_data, np.uint8), cv2.IMREAD_UNCHANGED)
    if depth_img_raw is None:
        # probably wrong header size
        raise Exception("Could not decode compressed depth image."
                        "You may need to change 'depth_header_size'!")

    if depth_fmt == "16UC1":
        # write raw image data
        # cv2.imwrite(os.path.join(path_depth, "depth_" + str(msg.header.stamp) + ".png"), depth_img_raw)
        return depth_img_raw
    elif depth_fmt == "32FC1":
        raw_header = msg.data[:depth_header_size]
        # header: int, float, float
        [compfmt, depthQuantA, depthQuantB] = struct.unpack('iff', raw_header)
        depth_img_scaled = depthQuantA / (depth_img_raw.astype(np.float32)-depthQuantB)
        # filter max values
        depth_img_scaled[depth_img_raw==0] = 0

        # depth_img_scaled provides distance in meters as f32
        # for storing it as png, we need to convert it to 16UC1 again (depth in mm)
        depth_img_mm = (depth_img_scaled*1000).astype(np.uint16)
        # cv2.imwrite(os.path.join(path_depth, "depth_" + str(msg.header.stamp) + ".png"), depth_img_mm)
        return depth_img_mm
    else:
        raise Exception("Decoding of '" + depth_fmt + "' is not implemented!")

def extract_images(bag_path, rgb_topic, depth_topic, output_dir, time_thre):
    # Create directories if they don't exist
    rgb_dir = os.path.join(output_dir, 'rgb')
    depth_dir = os.path.join(output_dir, 'depth')
    if not os.path.exists(rgb_dir):
        os.makedirs(rgb_dir)
    if not os.path.exists(depth_dir):
        os.makedirs(depth_dir)

    bridge = CvBridge()
    bag = rosbag.Bag(bag_path, 'r')

    rgb_images = []
    depth_images = []

    for topic, msg, t in bag.read_messages(topics=[rgb_topic, depth_topic]):
        if topic == rgb_topic:
            try:
                rgb_image = bridge.compressed_imgmsg_to_cv2(msg, "bgr8")
                rgb_images.append((t, rgb_image))
            except Exception as e:
                print(f"Error converting RGB image: {e}")
        elif topic == depth_topic:
            try:
                # depth_image = bridge.compressed_imgmsg_to_cv2(msg, "16UC1")
                # depth_image = bridge.compressed_imgmsg_to_cv2(msg, desired_encoding='passthrough')
                depth_image = process_comp_depth_image(msg)
                depth_images.append((t, depth_image))
            except Exception as e:
                print(f"Error converting depth image: {e}")

    bag.close()

    # Synchronize RGB and depth images by timestamp
    synchronized_images = []
    depth_times = {depth_time: depth_img for depth_time, depth_img in depth_images}
    current_depth_time = 0

    for rgb_time, rgb_img in rgb_images:
        closest_depth_time = min(depth_times.keys(), key=lambda t: abs(t - rgb_time))
        close_thre = rospy.Duration(time_thre)
        # if abs(closest_depth_time - rgb_time) < close_thre:
        if abs(closest_depth_time - rgb_time) < close_thre and current_depth_time != closest_depth_time:
            print("close!", rgb_time, closest_depth_time, abs(closest_depth_time - rgb_time), close_thre)
            synchronized_images.append((rgb_img, depth_times[closest_depth_time], rgb_time))
            current_depth_time = closest_depth_time

    print("synchronized num: ", len(synchronized_images), "depth images num: ", len(depth_images))
    # Save synchronized images
    for i, (rgb_img, depth_img, rgb_time) in enumerate(synchronized_images):
        rgb_filename = os.path.join(rgb_dir, f"{rgb_time}.png")
        depth_filename = os.path.join(depth_dir, f"{rgb_time}.png")

        cv2.imwrite(rgb_filename, rgb_img)
        cv2.imwrite(depth_filename, depth_img.astype(np.uint16))

    print(f"Saved {len(synchronized_images)} synchronized images to {output_dir}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Extract synchronized RGB and depth images from a ROS bag.')
    parser.add_argument('--bag_path', '-b', default='/media/almagest/73B2/kanazawa/videos/PR2-experiment/20240607/20240607_kitchen_bags/20240607_kitchen_bag_10.bag',type=str, help='Path to the ROS bag file.')
    parser.add_argument('--rgb_topic', '-r', default='/kinect_head/rgb/image_color/compressed', type=str, help='RGB image topic name.')
    parser.add_argument('--depth_topic', '-d', default='/kinect_head/depth_registered/image_raw/compressedDepth', type=str, help='Depth image topic name.')
    parser.add_argument('--output_dir', '-o', default='/home/kanazawa/Downloads/20240614_tracking_test/20240607_kitchen_bag_10_onion', type=str, help='Directory to save the extracted images.')
    parser.add_argument('--time_thre', '-t', default=0.002, type=float, help='Time threshold for sync.') # 0.05, 50ms tolerance

    args = parser.parse_args()
    extract_images(args.bag_path, args.rgb_topic, args.depth_topic, args.output_dir, args.time_thre)
