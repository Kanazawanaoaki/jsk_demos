# known_object_recognition

既知物体認識の自分用のメモ

## FoundationPoseを使う
https://github.com/W567/tracking を使う．

### Data Collection
(D435を使う場合)カメラのlaunchを立ち上げる
```bash
roslaunch realsense2_camera rs_rgbd.launch color_height:=480 color_width:=640 color_fps:=60 depth_height:=480 depth_width:=640 depth_fps:=60
```
そのままで使うときのrviz
```bash
roslaunch jsk_2023_09_cook_from_recipe realsense_rgbd_rviz.launch
```

データ保存のlaunch
```bash
roslaunch jsk_2023_09_cook_from_recipe rgb_and_depth_data_collection.launch rgb_image:=/camera_remote/rgb/image_raw depth_image:=/camera/aligned_depth_to_color/image_raw specified_dir_name:=sample_images
```

データの取得を開始する
```
rosservice call /rgb_and_depth_image_saver/start_sync "{}"
```
データの取得を終了する
```
rosservice call /rgb_and_depth_image_saver/stop_sync "{}"
```

### Data annotation

