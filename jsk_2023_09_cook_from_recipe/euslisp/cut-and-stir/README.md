## cut and stir


### 実行
launchを立ち上げる
```
roslaunch jsk_pr2_startup rviz.launch
roslaunch jsk_2023_09_cook_from_recipe use_k4a_remote.launch
roslaunch jsk_2023_09_cook_from_recipe kitchen_template_matching_k4a.launch
roslaunch jsk_2023_09_cook_from_recipe pr2_decompress.launch gui:=true
```

位置に移動
```
roscd jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir
rlwrap roseus pr2_cut_food.l
(reset-move-pose)
(move-to-spot "kitchen")
```

位置のチェック
```
roslaunch icp_registration_test.launch pcd_name:=kitchen_look
```
この状態で何かをsubscribeしてチェックをしたいような気もするけどねなど．

### テスト
テストを実行する

#### rosbagをとるなど
```bash
roslaunch jsk_2023_09_cook_from_recipe pr2_rosbag_record.launch rosbag:=/home/kanazawa/Desktop/data/rosbags/20240531_kitchen_bags/20240531_kitchen_bag_00
```

#### 物体認識
サーバPCで
```bash
source ~/ros/known_object_ws/devel/setup.bash 
roscd tracking_ros_utils/../tracking_ros
./run_docker -host pr1040 -launch deva.launch     input_image:=/kinect_head/rgb/image_rect_color     model_type:=vit_t     device:=cuda:0
```

手元で
```bash
roslaunch jsk_2023_09_cook_from_recipe deva_apply_track_object_mask.launch
```
これでdevaの物体認識ができる
```bash
rosrun dynamic_reconfigure dynparam set /deva_node classes "light;"
```
その結果から物体を掴むなど
```
roscd jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir
rlwrap roseus pr2_cut_food.l
;; (reset-move-pose)
(grasp-rec-object :object-name "knife")
```

#### Viveから操縦
Viveをセットアップする  

Vive用PCで
steamVRの起動
https://github.com/HiroIshida/vive_ros?tab=readme-ov-file#usage

```bash
rossetmaster pr1040
rossetip
roslaunch vive_ros vive_ctrl.launch
rqt_image_view
```

手元のPCで
https://github.com/HiroIshida/mohou_ros/tree/master?tab=readme-ov-file#3-save-rosbag
```bash
rosrun mohou_ros vive_controller_pr2.py -pn test
```