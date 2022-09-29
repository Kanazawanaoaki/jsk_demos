# jsk_2022_09_fridge_pi

fridge-pi のシステムと連動したロボットデモシステム．
https://github.com/Kanazawanaoaki/jsk_3rdparty/tree/fridge-pi-devel/m5stack_ros

## fridge pi robot side start up
1つのlaunchにまとめるのが良いかも．ロボット側で立ち上げるプログラム．
```
rosrun smach_viewer smach_viewer.py
rosrun jsk_2022_09_fridge_pi robot-state-smach.l
rosrun jsk_2022_09_fridge_pi firdge_pi_task_server.py
roslaunch rosbridge_server rosbridge_websocket.launch
```

## fridge pi fridfe side exec
```
rosrun m5stack_ros roslibpy_fridge_door.py
```
