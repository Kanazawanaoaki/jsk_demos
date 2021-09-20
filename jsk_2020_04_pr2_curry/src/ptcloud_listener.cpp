#include "ros/ros.h"
#include "std_msgs/String.h"
#include <sensor_msgs/PointCloud2.h>

void chatterCallback(const std_msgs::String::ConstPtr& msg)
{
  ROS_INFO("I heard: [%s]", msg->data.c_str());
}

void ptcloudCallback(const sensor_msgs::PointCloud2::ConstPtr& msg_ptcloud)
{
  
  ROS_INFO("I heard: [%d]", msg_ptcloud->data); // TODO ここのフォーマット指定子を直すとか色々やらないといけない
  // ROS_INFO("header is: [%s]", msg_ptcloud->header);
}

int main(int argc, char **argv)
{
  ros::init(argc, argv, "ptcloud_listener");
  
  ros::NodeHandle n;
  
  // ros::Subscriber sub = n.subscribe("chatter", 1000, chatterCallback);
  ros::Subscriber sub = n.subscribe("/kinect_head/depth_registered/throttled/points", 1000, ptcloudCallback);
  
  ros::spin();

  return 0;
}
