#!/usr/bin/env python
# -*- coding: utf-8 -*-

import rospy
import time
import roslibpy

class rosbridge_client:
    def __init__(self):
        # self.ros_client = roslibpy.Ros('133.11.216.106', 9090)
        self.ros_client = roslibpy.Ros('133.11.216.67', 9090)
        print("wait for server")
        self.publisher = roslibpy.Topic(
            self.ros_client, '/fetch_robot_state', 'std_msgs/Bool')

        self.ros_client.on_ready(self.start_thread, run_in_thread=True)
        print("run forever")
        self.ros_client.run_forever()

    def start_thread(self):
        while True:
            if self.ros_client.is_connected:
                self.publisher.publish(roslibpy.Message({'data': True}))
            else:
                print("Disconnect")
                break
            time.sleep(1.0)


if __name__ == '__main__':
    rosbridge_client()
