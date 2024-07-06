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
```bash
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

#### 音声対話で操縦
```bash
roscd jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir
rlwrap roseus pr2_cut_food.l
(dialogue-manip)
```

#### 3Dマウスで操縦
launch
```bash
roslaunch spacenav_node classic.launch 
```
eus
```bash
roscd jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir
rlwrap spacenav-teleop-test.l
(spacenav-teleop)
```


#### モデルを作る

##### devaバージョン
devaを立ち上げている状態で
```bash
roslaunch tf_trans_with_hand_tf.launch gui:=true input:=/extract_indices/output target_frame:=r_gripper_tool_frame
```
```bash
roslaunch service_save_ptcloud_in_pcd.launch object_name:=white_cup INPUT:=/tf_transform_cloud/output
```
```bash
roscd jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir
rlwrap roseus pr2_cut_food.l
(reset-move-pose)
(test-make-model :grasp-gain 1.0 :step-deg 20 :open-gripper t)
```

##### gripper相対バージョン
gripperの相対プログラム
```bash
roslaunch gripper_attention_test.launch
```
```bash
roslaunch tf_trans_with_hand_tf.launch gui:=true input:=/gripper_extract_indices/output target_frame:=r_gripper_tool_frame
```
```bash
roslaunch service_save_ptcloud_in_pcd.launch object_name:=green_bowl INPUT:=/tf_transform_cloud/output
```

```bash
roscd jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir
rlwrap roseus pr2_cut_food.l
(reset-move-pose)
(test-make-model :grasp-gain 1.0 :step-deg 20 :open-gripper t)
```

### 物体点群をrosbagから取り出す
rosbagを再生
```
roslaunch jsk_2023_09_cook_from_recipe pr2_rosbag_play.launch rosbag:=/media/almagest/73B2/kanazawa/videos/PR2-experiment/20240706/20240706_kitchen_bags/20240706_kitchen_bag_01.bag
```
サーバPCで
```bash
source ~/ros/known_object_ws/devel/setup.bash 
roscd tracking_ros_utils/../tracking_ros
./run_docker -host localhost -launch deva.launch input_image:=/kinect_head_remote/rgb/image_rect_color model_type:=vit_t device:=cuda:0
```

手元で
```bash
roslaunch jsk_2023_09_cook_from_recipe deva_apply_track_object_mask.launch
```
これでdevaの物体認識ができる
```bash
rosrun dynamic_reconfigure dynparam set /deva_node classes "light;"
```
その点群を保存する話
```bash
roslaunch jsk_2023_09_cook_from_recipe tf_trans_with_hand_tf.launch gui:=true input:=/extract_indices/output target_frame:=objectoutput00
```
```bash
roslaunch jsk_2023_09_cook_from_recipe service_save_ptcloud_in_pcd.launch object_name:=white_cup INPUT:=/tf_transform_cloud/output
## or
roslaunch jsk_2023_09_cook_from_recipe save_ptcloud_in_pcd.launch INPUT:=/tf_transform_cloud/output
```
