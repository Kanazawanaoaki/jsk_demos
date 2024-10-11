#include <m5stack_ros.h>
#include <sgp30_multigasv2_env3.h>
#include <std_msgs/UInt16.h>
#include <std_msgs/Float32.h>
#include <sound_play/SoundRequestActionGoal.h>

std_msgs::UInt16 tvoc_msg;
ros::Publisher tvoc_pub("tvoc", &tvoc_msg);
std_msgs::UInt16 eco2_msg;
ros::Publisher eco2_pub("eco2", &eco2_msg);
sound_play::SoundRequestActionGoal sound_msg;
ros::Publisher sound_pub("sound_play/goal", &sound_msg);
long last_sound_play = 0;

std_msgs::UInt16 gas_v2_102b_msg;
std_msgs::UInt16 gas_v2_302b_msg;
std_msgs::UInt16 gas_v2_502b_msg;
std_msgs::UInt16 gas_v2_702b_msg;
ros::Publisher gas_v2_102b_pub("gas_v2_102b", &gas_v2_102b_msg);
ros::Publisher gas_v2_302b_pub("gas_v2_302b", &gas_v2_302b_msg);
ros::Publisher gas_v2_502b_pub("gas_v2_502b", &gas_v2_502b_msg);
ros::Publisher gas_v2_702b_pub("gas_v2_702b", &gas_v2_702b_msg);

std_msgs::Float32 tmp_msg;
ros::Publisher tmp_pub("temperature", &tmp_msg);
std_msgs::Float32 hum_msg;
ros::Publisher hum_pub("humidity", &hum_msg);
std_msgs::Float32 pressure_msg;
ros::Publisher pressure_pub("pressure", &pressure_msg);

void publishENV() {
  tmp_msg.data = tmp;
  hum_msg.data = hum;
  pressure_msg.data = pressure;
  tmp_pub.publish(&tmp_msg);
  hum_pub.publish(&hum_msg);
  pressure_pub.publish(&pressure_msg);
}

void setup() {
  setupM5stackROS("M5Stack ROS TVOC SGP30 and Gas V2 and ENV3");
  setupTVOCSGP30_GasV2_ENV();

  nh.advertise(tvoc_pub);
  nh.advertise(eco2_pub);
  nh.advertise(sound_pub);
  nh.advertise(gas_v2_102b_pub);
  nh.advertise(gas_v2_302b_pub);
  nh.advertise(gas_v2_502b_pub);
  nh.advertise(gas_v2_702b_pub);
  nh.advertise(tmp_pub);
  nh.advertise(hum_pub);
  nh.advertise(pressure_pub);
}

void loop() {
  measureTVOCSGP30_GasV2_ENV();

  tvoc_msg.data = sgp.TVOC;
  tvoc_pub.publish(&tvoc_msg);
  eco2_msg.data = sgp.eCO2;
  eco2_pub.publish(&eco2_msg);
  gas_v2_102b_msg.data = val_102B;
  gas_v2_302b_msg.data = val_302B;
  gas_v2_502b_msg.data = val_502B;
  gas_v2_702b_msg.data = val_702B;
  gas_v2_102b_pub.publish(&gas_v2_102b_msg);
  gas_v2_302b_pub.publish(&gas_v2_302b_msg);
  gas_v2_502b_pub.publish(&gas_v2_502b_msg);
  gas_v2_702b_pub.publish(&gas_v2_702b_msg);
  if ( millis() - last_sound_play > 30000 && sgp.eCO2 > 1000 ) {
    sound_msg.goal.sound_request.sound = -3;
    sound_msg.goal.sound_request.command = 1;
    sound_msg.goal.sound_request.volume = 1.0;
    sound_msg.goal.sound_request.arg = "C O 2 concentration is high. Please change the air.";
    sound_pub.publish(&sound_msg);
    last_sound_play = millis();
  }

  publishENV();

  nh.spinOnce();
  delay(1000);
}
