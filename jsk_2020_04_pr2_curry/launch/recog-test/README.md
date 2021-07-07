# recog-test


### PR2 73B2 rosbag
record and play with [this PR](https://github.com/jsk-ros-pkg/jsk_robot/pull/1228 )

#### record
```
source ~/semi_ws/devel/setup.bash
roslaunch jsk_pr2_startup rosbag_record.launch rosbag:=/home/kanazawa/Desktop/rosbags/PR2/20200706_kanazawa_kitchen/202007061723_kitchen_01
```

#### play
20200702
```
cd ~/Desktop/rosbags/PR2/20200702_kanazawa_kitchen
source ~/semi_ws/devel/setup.bash
roslaunch jsk_pr2_startup rosbag_play.launch rosbag:=/home/kanazawa/Desktop/rosbags/PR2/20200702_kanazawa_kitchen/202007021723_kitchen_12_potato_on_board.bag gui:=true
```
20200708
```
cd ~/Desktop/rosbags/PR2/20200708_kanazawa_kitchen/
roslaunch jsk_pr2_startup rosbag_play.launch rosbag:=/home/kanazawa/Desktop/rosbags/PR2/20200708_kanazawa_kitchen/20200708_kitchen_02.bag gui:=true
```

In this rosbag,  
pointclouds:`/kinect_head/depth_registered/throttled/points`  
image:`/kinect_head/rgb/image_rect_color`

#### data_collection_server
[using data_collection_server](https://jsk-common.readthedocs.io/en/latest/jsk_data/node_scripts/data_collection_server.html ) to save data from rostopic
```
source ~/ros/jsk_demo_ws/devel/setup.bash
roslaunch kitchen_recognition pr2_data_collection_server_test.launch
```
```
rosservice call /after_stow_data_collection/save_request "{}"
```

#### save ptcloud to PCD
```
source ~/semi_ws/devel/setup.bash
roslaunch jsk_2020_04_pr2_curry ptcloud2pcd_pr2_test.launch
```

#### pcd to ptcloud
```
source ~/semi_ws/devel/setup.bash
roslaunch jsk_2020_04_pr2_curry pcd_to_ptcloud_pr2.launch pcd:=/home/kanazawa/semi_ws/src/jsk_demos/jsk_2020_04_pr2_curry/pcd/potato_on_board_0702.pcd
```

### pcd with rosbag
pcd to ptcloud with play rosbag.

#### pcd and rosbag launch
```
source ~/semi_ws/devel/setup.bash
roslaunch jsk_2020_04_pr2_curry pcd_rosbag_test.launch pcd:=/home/kanazawa/semi_ws/src/jsk_demos/jsk_2020_04_pr2_curry/pcd/carrot_on_board_0708.pcd
```

#### tabletop recog
```
source ~/semi_ws/devel/setup.bash
roslaunch jsk_2020_04_pr2_curry tabletop_pcd_test.launch
```

#### cutting board top recog
```
source ~/semi_ws/devel/setup.bash
roslaunch jsk_2020_04_pr2_curry cutting_board_top_pcd.launch
```

#### make box in eus
```
source ~/semi_ws/devel/setup.bash
roscd jsk_2020_04_pr2_curry/euslisp/recog-test/
rlwrap roseus box-with-rec.l
```
