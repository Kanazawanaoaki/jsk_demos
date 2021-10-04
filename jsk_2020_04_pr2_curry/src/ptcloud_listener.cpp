#include "ros/ros.h"
#include "std_msgs/String.h"
#include <sensor_msgs/PointCloud2.h>
#include <pcl_conversions/pcl_conversions.h>

#include <typeinfo>
#include <iostream>

// #include <pcl/visualization/cloud_viewer.h>
#include <pcl/visualization/pcl_visualizer.h>

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

  // pcl::visualization::CloudViewer viewer("Simple Cloud Viewer");
  // pcl::PointCloud<pcl::PointXYZ>::Ptr cloud_ptr(new pcl::PointCloud<pcl::PointXYZ>(pointcloud));
  // viewer.showCloud(cloud_ptr);


  // pcl::visualization::PCLVisualizer viewer("Simple Cloud Viewer");
  // viewer.setBackgroundColor(0.0, 0.0, 0.0);
  // viewer.addPointCloud<pcl::PointXYZ>(pointcloud, "cloud", 0);
  
  // // ビューワー視聴用ループ
  // while (!viewer.wasStopped())
  //   {
  //     viewer.spinOnce();
  //   }
}

int main(int argc, char **argv)
{
  ros::init(argc, argv, "ptcloud_listener");
  
  ros::NodeHandle n;
  
  ros::Subscriber sub = n.subscribe("/kinect_head/depth_registered/throttled/points", 1000, ptcloudCallback);
  
  ros::spin();

  return 0;
}
