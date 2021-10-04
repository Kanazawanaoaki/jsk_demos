#include "ros/ros.h"
#include "std_msgs/String.h"
#include <sensor_msgs/PointCloud2.h>
#include <pcl_conversions/pcl_conversions.h>

#include <typeinfo>
#include <iostream>

// #include <pcl/visualization/pcl_visualizer.h>

class PtcloudListenerClass
{
private:
  ros::NodeHandle n_;  
  ros::Publisher pub_;
  ros::Subscriber sub_;

public:
  void ptcloudCallback(const sensor_msgs::PointCloud2::ConstPtr& msg_ptcloud);

  PtcloudListenerClass()
  {
    // sub_ = n_.subscribe("/kinect_head/depth_registered/throttled/points", 1000, &PtcloudListenerClass::ptcloudCallback, this);
    sub_ = n_.subscribe("input", 1000, &PtcloudListenerClass::ptcloudCallback, this);
    pub_ = n_.advertise<sensor_msgs::PointCloud2>("ptcloud_test/msg_debug_points", 1000);
    // pub_ = n_.advertise<sensor_msgs::PointCloud2>("output", 1000);
  }
};


void PtcloudListenerClass::ptcloudCallback(const sensor_msgs::PointCloud2::ConstPtr& msg_ptcloud)
{
  ROS_INFO("header stamp is: [%d]", msg_ptcloud->header.stamp);

  // transform rosmsg to pointcloud
  pcl::PointCloud<pcl::PointXYZ> pointcloud;
  pcl::fromROSMsg(*msg_ptcloud, pointcloud);
  std::cout << "len is: " << pointcloud.size() << std::endl;
  std::cout << "fisrt point x: " << pointcloud.points[100] << std::endl;

  // // オウム返し
  // sensor_msgs::PointCloud2 msg_debug_points;
  // pcl::toROSMsg(pointcloud, msg_debug_points);
  // msg_debug_points.header = msg_ptcloud->header;
  // pub_.publish(msg_debug_points);

  // 点群処理を書いていく

  // zの最大値を探る
  // double max_z = 0;
  // for (pcl::PointCloud<pcl::PointXYZ>::iterator p = pointcloud.points.begin(); p != pointcloud.points.end(); *p++) {
  //   if (p->z > max_z){
  //     max_z = p->z;
  //   }
  // }  
  // std::cout << "max z is : " << max_z << std::endl;

  // zがある値の点群を取り出す
  double z_val = 1.0;
  double z_tolerance = 0.1;
  double z_points_num = 0;
  pcl::PointCloud<pcl::PointXYZ> z_points;
  for (pcl::PointCloud<pcl::PointXYZ>::iterator p = pointcloud.points.begin(); p != pointcloud.points.end(); *p++) {
    if (p->z < (z_val + z_tolerance) and (z_val - z_tolerance) < p->z ){
      z_points_num++;
      z_points.push_back(pcl::PointXYZ(p->x, p->y, p->z));
    }
  }    
  sensor_msgs::PointCloud2 msg_debug_points;
  pcl::toROSMsg(z_points, msg_debug_points);
  msg_debug_points.header = msg_ptcloud->header;
  pub_.publish(msg_debug_points);
  std::cout << "z points num is : " << z_points_num << std::endl;  
}

int main(int argc, char **argv)
{
  ros::init(argc, argv, "ptcloud_listener");
  
  PtcloudListenerClass ptcloudlistenerclass;

  ros::spin();
}
