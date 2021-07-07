import rosbag
from tf_bag import BagTfTransformer
import rospy




directory = "/home/leus/bag_vision"
bagfile_vision = "%s/2019-11-08-19-18-47.bag" % directory

bag = rosbag.Bag(bagfile_vision)

bag_transformer = BagTfTransformer(bag)
print bag_transformer.getTransformGraphInfo()

first_transform_time = bag_transformer.waitForTransform("base_footprint", "head_mount_kinect_rgb_optical_frame")
#first_transform_time = bag_transformer.waitForTransform("head_mount_kinect_rgb_optical_frame","base_footprint")
print first_transform_time
print type(first_transform_time)
#first and last timestamps
#1573208327820173191
#1573208459084019588
#first_point_cloud = rospy.Time(secs = 1573208380,nsecs = 563954077)
first_point_cloud = rospy.Time(secs = 1573208459,nsecs = 84019588)
print first_point_cloud
print type(first_point_cloud)
#time of first point cloud is 1573208165
translation, quaternion = bag_transformer.lookupTransform("base_footprint", "head_mount_kinect_rgb_optical_frame", first_point_cloud)
#translation, quaternion = bag_transformer.lookupTransform("head_mount_kinect_rgb_optical_frame","base_footprint", first_point_cloud)
print translation
print quaternion
