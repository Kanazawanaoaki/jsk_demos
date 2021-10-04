#include "ros/ros.h"
#include "std_msgs/String.h"
#include <sensor_msgs/PointCloud2.h>
#include <pcl_conversions/pcl_conversions.h>

#include <typeinfo>
#include <iostream>

// #include <pcl/visualization/pcl_visualizer.h>

void ptcloudCallback(const sensor_msgs::PointCloud2::ConstPtr& msg_ptcloud)
{
  // std::cout << "header is: " << typeid(msg_ptcloud->header.stamp).name() << std::endl;
  // ROS_INFO("I heard: [%d]", msg_ptcloud->data); // ここのフォーマット指定子を直すとかできたら良い

  ROS_INFO("header stamp is: [%d]", msg_ptcloud->header.stamp);

  // transform rosmsg to pointcloud
  pcl::PointCloud<pcl::PointXYZ> pointcloud;
  pcl::fromROSMsg(*msg_ptcloud, pointcloud);
  // std::cout << "header is: " << typeid(pointcloud).name() << std::endl;

  std::cout << "len is: " << pointcloud.size() << std::endl;
  std::cout << "fisrt point x: " << pointcloud.points[100] << std::endl;

  // pcl::visualization::PCLVisualizer viewer("PCLVisualizer");
  // viewer.setBackgroundColor(0.0, 0.0, 0.0);
  // viewer.addPointCloud<pcl::PointXYZ>(pointcloud, "cloud", 0);
  
  // // ビューワー視聴用ループ
  // while (!viewer.wasStopped())
  //   {
  //     viewer.spinOnce();
  //   }

  ros::NodeHandle pn;
  ros::Publisher pub_debug_points = pn.advertise<sensor_msgs::PointCloud2>("/ptcloud_test/msg_debug_points", 1000);

  sensor_msgs::PointCloud2 msg_debug_points;
  pcl::toROSMsg(pointcloud, msg_debug_points);
  msg_debug_points.header = msg_ptcloud->header;
  // msg_debug_points.header.frame_id = world_frame_;
  //msg_debug_points.header.stamp = ros::Time::now();
  pub_debug_points.publish(msg_debug_points);

  std::cout << "hoge " << std::endl;
}

int main(int argc, char **argv)
{
  ros::init(argc, argv, "ptcloud_listener");

  ros::NodeHandle n;
  
  // ros::Publisher pub_debug_points = n.advertise<sensor_msgs::PointCloud2>("ptcloud_test/msg_debug_points", 1000);
  ros::Subscriber sub = n.subscribe("/kinect_head/depth_registered/throttled/points", 1000, ptcloudCallback);
  
  ros::spin();

  return 0;
}
