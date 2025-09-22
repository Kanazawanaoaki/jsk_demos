# 目玉焼きの実験手順

counterで卵を割って，stoveに移動し，フライパンに油を注いで，卵を注いで，火が通ったら，盛り付ける．


## 実行準備

### C2で立ち上げておく
（ https://github.com/Kanazawanaoaki/OrbbecSDK_ROS1/tree/for-pr1040 のブランチを使っているので）
```bash
roslaunch orbbec_camera pr1040_femto_mega.launch
```
### （手首のカメラを使う場合は）pr1040nで立ち上げておく
```bash
roslaunch jsk_2023_09_cook_from_recipe r_hand_d405.launch ## ~/kanazawa_ws
```

### デスクトップで立ち上げておくもの第一弾（カメラの再構成関係）
```bash
roslaunch jsk_2023_09_cook_from_recipe pr2_decompress.launch ## 無くても良いかも
roslaunch jsk_2023_09_cook_from_recipe use_femto_mega_remote.launch

## 手首のカメラを使う場合には
roslaunch jsk_2023_09_cook_from_recipe use_r_hand_d405_remote.launch
```


### デスクトップで立ち上げておくもの第二段（FoundationPose）
その前に手元で立ち上げておくと良いもの
```bash
roslaunch tracking gui.launch button_gui:=true rgb_topic:=/tracking/rgb_topic
```
デスクトップで立ち上げる
```bash
## for FoundationPose 3D(6D) tracking
roscd jsk_perception/docker ## ~/ros/jsk_demo_ws
./run_jsk_vil_api dino --port 8080 -g 0
roscd tracking/docker ## ~/ros/tracking_ws
./run_docker.py -host pr1040 -cuda 2 -launch track.launch mode:=track mesh:=kn_green_bowl_20241017_wu_blender label:=green-bowl rec_model:=groundingdino seg_model:=sam2 camera_type:=kinect camera_tf_frame:=femto_mega_color_optical_frame decompress:=true depth_topic:=/femto_mega/depth/image_raw rgb_topic:=/femto_mega/color/image_raw info_topic:=/femto_mega/color/camera_info rec_port:=8080 fix_name:=true track_debug:=true remote:=true
```

### デスクトップで立ち上げておくもの第三段（devaとpcl）
```bash
roscd tracking_ros_utils/../tracking_ros ## ~/ros/known_object_ws
./run_docker -host pr1040 -launch deva.launch input_image:=/femto_mega_remote/color/image_raw model_type:=vit_t device:=cuda:0


```


### 手元で立ち上げておく
```bash
roslaunch jsk_2023_09_cook_from_recipe view_rviz_cook.launch rviz_name:=view_rviz_cook_mega ## もし立ち上がっていなければ

## テンプレートマッチング
roslaunch jsk_2023_09_cook_from_recipe kitchen_template_matching_femto_mega.launch

## IHテンプレートマッチング
roslaunch jsk_2023_09_cook_from_recipe kitchen_template_matching_rd405.launch ## 手首カメラでのテンプレートマッチングを使う，IHなど
```


## 実行する
roseusのプログラムを立ち上げる
```bash
roscd jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/
rlwrap roseus test-sunny-side-up-with-move-demo.l
```

移動パラメータの変更
```lisp
(change-move-params)
```

準備
```lisp
## stoveの準備
(sunny-side-up-prepare :spot "stove")

## counterの準備
(sunny-side-up-prepare :spot "counter")
```

実行
```lisp
## 全て実行
(do-all-sunny)

## counterでの作業のみ
(counter-sunny)

## stoveでの作業のみ
(stove-test)
```


移動パラメータを戻す
```lisp
(set-default-move-params)
(show-current-move-params)
```
