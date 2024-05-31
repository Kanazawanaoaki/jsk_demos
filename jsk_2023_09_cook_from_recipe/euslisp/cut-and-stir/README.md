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
