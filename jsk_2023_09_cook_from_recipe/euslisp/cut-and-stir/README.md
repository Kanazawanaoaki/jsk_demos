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
rossetlocal
rossetip
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

### 動作の教示
```bash
(cook-teach)
(dump-cook-from-now-file :file_name "[Your File Name]")
```

### 匂いセンサを使う
https://github.com/708yamaguchi/jsk_3rdparty/tree/m5stack-ros-/m5stack_ros でセットアップをする

#### Unique device file name by udev rules

When multiple M5 devices are used with USB connections to the same PC, their device files must be distinguished.
With the following steps, different symbolic links are created for each M5 device. You can use [udev file example](https://github.com/708yamaguchi/jsk_3rdparty/blob/m5stack-ros-/m5stack_ros/config/99-m5stack-ros.rules).

  - Check ATTRS{idVendor} and ATTRS{idProduct} by the following command
    ```
    lsusb
    ```

  - Check ATTRS{serial} by
    ```
    M5_DEVICE_FILE=/dev/ttyUSB0
    sudo udevadm info -a -p $(sudo udevadm info -q path -n $M5_DEVICE_FILE) | grep ATTRS{serial}
    ```

  - Place your udev files file under `/etc/udev/rules.d/`
    ```
    sudo cp $(rospack find jsk_2023_09_cook_from_recipe)/config/udev/99-kanazawa-cook-sensors.rules /etc/udev/rules.d/
    ```

  - Restart udev
    ```
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    ```

  - Reconnect your M5 device and check if symbolic link (/dev/[Device name]) is created.

#### 匂いセンサの利用
センサセットをUSB接続して，m5stack_rosのWSをsourceしている状況で以下を実行してrostopicを出力
```bash
roslaunch gas_sensors.launch
```
このリポジトリでのセンサ利用のためのutilsを立ち上げる
```bash
roslaunch jsk_2023_09_cook_from_recipe utils_for_gas_sensors.launch
```
データの取得を開始する
```bash
rosservice call /sensors_data_saver/start_saving "{}"
```
データの取得を終了する
```bash
rosservice call /sensors_data_saver/stop_saving "{}"
```

#### カメラセンサも利用
```bash
roslaunch jsk_2023_09_cook_from_recipe d435_camera_with_decomp.launch
```

データの保存（このlaunchはutils_for_gas_sensors.launchに含まれている）
```bash
roslaunch jsk_2023_09_cook_from_recipe periodic_image_saver.launch
```

データの取得を開始する
```bash
rosservice call /periodic_image_saver/start_saving "{}"
```
データの取得を終了する
```bash
rosservice call /periodic_image_saver/stop_saving "{}"
```

#### plotする
rosbagのファイルをcsvに変換する
```bash
python rosbag_to_csv.py -b /home/kanazawa/Desktop/data/rosbags/20240922_hp_bags/20240922_hp_bag_cook_sunny_03_cook_sensors_01.bag
```

ディレクトリ毎にすべてのセンサ値をplotする
```bash
roscd jsk_2023_09_cook_from_recipe/scripts/cook_sensors
python all_plot_sensor_value.py /home/kanazawa/ros/cooking_ws/src/jsk_demos/jsk_2023_09_cook_from_recipe/datas/sensor_datas/20240922_hp_bag_cook_sunny_03_cook_sensors_01 -j
```
個別のセンサの値のcsvをplotする
```bash
roscd jsk_2023_09_cook_from_recipe/scripts/cook_sensors
python plot_sensor_value.py /home/kanazawa/ros/cooking_ws/src/jsk_demos/jsk_2023_09_cook_from_recipe/datas/sensor_datas/20240922_hp_bag_cook_sunny_03/timestamped_tgs_2603_analog.csv -j
```
上の2つのplotを一度に行える便利実行スクリプトも用意した
```bash
python exec_gas_sensors_plot.py /home/kanazawa/ros/cooking_ws/src/jsk_demos/jsk_2023_09_cook_from_recipe/datas/sensor_datas/20240922_hp_bag_cook_sunny_01_cook_sensors_02
```



### BundleSDF and FoundationPose
#### Data Collection
Launch the D435 camera launch file.
```bash
roslaunch jsk_2023_09_cook_from_recipe d435_camera_with_decomp.launch
```
Launching a data collection node.
```bash
roscd jsk_2023_09_cook_from_recipe/scripts/for-cut/
python rgb_and_depth_image_saver.py
```

Start collecting data.
```bash
rosservice call /rgb_and_depth_saver/start_sync "{}"
```
Stop collecting data.
```bash
rosservice call /rgb_and_depth_saver/stop_sync "{}"
```

### Rvizでインタラクティブに座標指定
```
roslaunch jsk_2023_09_cook_from_recipe interactive_tf_pr2.launch
```
で立ち上げたrvizでインタラクティブマーカを移動させる
```
rosrun tf tf_echo base_footprint tf2
```
等で座標を取得することも可能


### gripperのキャリブを確認する
```bash
(reset-cook-pose)
(kitchen-pose-calib-check)
```

### Z800も使うバージョン

Z800で立ち上げる
```bash
roslaunch jsk_2023_09_cook_from_recipe pr2_decompress.launch
roslaunch jsk_2023_09_cook_from_recipe use_k4a_remote.launch
roslaunch jsk_2023_09_cook_from_recipe gripper_tape_for_calib.launch  run_rviz:=false
roslaunch jsk_2023_09_cook_from_recipe ns_tabletop_and_deva_apply_mask.launch run_tabletop:=true run_rviz:=false run_deva_only:=true
```
TRで立ち上げる
```bash
source ~/ros/known_object_ws/devel/setup.bash 
roscd tracking_ros_utils/../tracking_ros
./run_docker -host pr1040 -launch deva.launch     input_image:=/kinect_head/rgb/image_rect_color     model_type:=vit_t     device:=cuda:0
```
手元PCでrvizを立ち上げる
```
roslaunch jsk_pr2_startup rviz.launch
roslaunch jsk_2023_09_cook_from_recipe view_rviz_cook.launch 
```

必要に応じて立ち上げる
```
roslaunch jsk_2023_09_cook_from_recipe kitchen_template_matching_k4a.launch
roslaunch jsk_2023_09_cook_from_recipe interactive_tf_pr2.launch
```