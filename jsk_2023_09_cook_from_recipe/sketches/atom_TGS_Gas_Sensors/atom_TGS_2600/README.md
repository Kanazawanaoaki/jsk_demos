# TGS_2600

Publish [TGS2600(Hydrogen, alcohol, etc.)](https://www.figaro.co.jp/product/entry/tgs2600.html).

## Overview

Communication:

- TGS_2600 <-(GPIO)-> M5Stack <-(Bluetooth/Wi-Fi/USB)-> PC
- Connect M5Stack and TGS_Gas_Sensors with Grove cable (Port.B) or jumper wire (Connect VCC and GND respectively, and connect analog output to pin 36 and digital output to pin 26).

Published topics:

- `/tgs_2600_analog` (`std_msgs/UInt16`)

  Sensor analog output value

- `/tgs_2600_digital` (`std_msgs/UInt16`)

  Sensor digital output value

## Usage

- Follow [README.md](https://github.com/jsk-ros-pkg/jsk_3rdparty/tree/master/m5stack_ros)

- Run

  ```bash
  roslaunch m5stack_ros m5stack_ros.launch
  ```
