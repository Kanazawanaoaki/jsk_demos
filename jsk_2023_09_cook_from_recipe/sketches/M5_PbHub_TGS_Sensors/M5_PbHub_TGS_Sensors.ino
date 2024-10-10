#include <m5_pbhub_tgs.h>
#include <m5stack_ros.h>
#include <std_msgs/UInt16.h>

std_msgs::UInt16 tgs_2600_analog_msg;
std_msgs::UInt16 tgs_2600_digital_msg;
std_msgs::UInt16 tgs_2602_analog_msg;
std_msgs::UInt16 tgs_2602_digital_msg;
std_msgs::UInt16 tgs_2603_analog_msg;
std_msgs::UInt16 tgs_2603_digital_msg;
ros::Publisher tgs_2600_analog_pub("tgs_2600_analog", &tgs_2600_analog_msg);
ros::Publisher tgs_2600_digital_pub("tgs_2600_digital", &tgs_2600_digital_msg);
ros::Publisher tgs_2602_analog_pub("tgs_2602_analog", &tgs_2602_analog_msg);
ros::Publisher tgs_2602_digital_pub("tgs_2602_digital", &tgs_2602_digital_msg);
ros::Publisher tgs_2603_analog_pub("tgs_2603_analog", &tgs_2603_analog_msg);
ros::Publisher tgs_2603_digital_pub("tgs_2603_digital", &tgs_2603_digital_msg);

void setup() {
  setupM5stackROS("M5Stack ROS TGS_Gas_Sensors with Pbhub");
  setupPbHubTGSSensors();  

  nh.advertise(tgs_2600_analog_pub);
  nh.advertise(tgs_2600_digital_pub);
  nh.advertise(tgs_2602_analog_pub);
  nh.advertise(tgs_2602_digital_pub);
  nh.advertise(tgs_2603_analog_pub);
  nh.advertise(tgs_2603_digital_pub);
}

void loop() {
  measurePbHubTGSSensors();
  displayPbHubTGSSensors();

  tgs_2600_analog_msg.data = a_value_2600;
  tgs_2600_digital_msg.data = d_value_2600;
  tgs_2600_analog_pub.publish(&tgs_2600_analog_msg);
  tgs_2600_digital_pub.publish(&tgs_2600_digital_msg);

  tgs_2602_analog_msg.data = a_value_2602;
  tgs_2602_digital_msg.data = d_value_2602;
  tgs_2602_analog_pub.publish(&tgs_2602_analog_msg);
  tgs_2602_digital_pub.publish(&tgs_2602_digital_msg);

  tgs_2603_analog_msg.data = a_value_2603;
  tgs_2603_digital_msg.data = d_value_2603;
  tgs_2603_analog_pub.publish(&tgs_2603_analog_msg);
  tgs_2603_digital_pub.publish(&tgs_2603_digital_msg);

  nh.spinOnce();
  delay(500);

//  Serial.printf("ch:%d adc:%d ddc:%d \r\n", ch, a_value, d_value);
//  delay(500);
}
