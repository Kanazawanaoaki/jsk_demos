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

データ保存のlaunch（specified_dir_nameを指定してフォルダ名変更，RGBとDepthとcamera infoを保存）
```bash
roslaunch jsk_2023_09_cook_from_recipe rgb_and_depth_data_collection.launch rgb_image:=/camera/color/image_raw depth_image:=/camera/aligned_depth_to_color/image_raw specified_dir_name:=sample_images
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
https://github.com/Kanazawanaoaki/sam2_annotation を使う（暫定）  
環境構築をしてsam2_annotationのディレクトリに移動．
#### convert png to jpg (if rgb image is png, this conversioin is needed.)
```bash
python png2jpg.py [input_dir] [output_dir]
```
#### split jpg dir (This is necessary if you have a lot of image files and are experiencing GPU memory issues.)
```bash
python data_split.py [input_dir] [output_dir] -n 2
```
#### annotate segmation to images
```bash
python interactive_video_predictor.py -i ../videos/bedroom -o ../output/bedroom
```
#### convert overlay_mask to video
```bash
python overlay_mask2video.py [overlay_mask] -o [output_file_name].mp4
```
#### convert jpg to grasy png
```bash
python jpg2graypng.py [input_dir] [output_dir]
```
#### image file dim check
```bash
python image_file_check.py [input_dir]
```

#### bundlesdf用のデータ形式にする
```bash
root
  ├──rgb/    (PNG files)
  ├──depth/  (PNG files, stored in mm, uint16 format. Filename same as rgb)
  ├──masks/       (PNG files. Filename same as rgb. 0 is background. Else is foreground)
  └──cam_K.txt   (3x3 intrinsic matrix, use space and enter to delimit)
```

#### checkする
点群の再構成をしてみる
```bash
roscd jsk_2023_09_cook_from_recipe/scripts/for-cut
python milk_ptcloud_construct.py -r [milk_data_rgb]
## if you want to use mask
python milk_ptcloud_construct.py -r [milk_data_rgb] -m
```
#### データの数を減らす
指定した番号以降の数のファイルを削除する
```bash
roscd jsk_2023_09_cook_from_recipe/scripts/for-cut
python check_and_delete.py  [path to directory] [delete start number]
```

### Mask STL file
https://github.com/NVlabs/BundleSDF を使う．

dockerを立ち上げる
```bash
docker rm -f bundlesdf
docker run --gpus all --env NVIDIA_DISABLE_REQUIRE=1 -it --network=host --name bundlesdf  --cap-add=SYS_PTRACE --security-opt seccomp=unconfined  -v /home/kanazawa/Desktop/codes/in_jsk/BundleSDF:/home/user/BundleSDF -v /tmp:/tmp -v /media/almagest/73B2/kanazawa/datas/milk_data/:/mnt -v $DIR:$DIR  --ipc=host -e DISPLAY=${DISPLAY} -e GIT_INDEX_FILE nvcr.io/nvidian/bundlesdf:latest bash
cd /home/user/BundleSDF/
bash build.sh
pip uninstall scipy
pip install scipy==1.9
```

`Ctrl + P + Q` でコンテナから抜けて，`docker exec -it bundlesdf /bin/bash`で中に入るとかもできそう．

#### 1) Run joint tracking and reconstruction. 
```bash
python run_custom.py --mode run_video --video_dir /mnt/source_datas/[dataset_name] --out_folder /mnt/bundlesdf/bundlesdf_[dataset_name] --use_segmenter 1 --use_gui 1 --debug_level 2
```

#### 2) Run global refinement post-processing to refine the mesh
```bash
python run_custom.py --mode global_refine --video_dir /mnt/source_datas/[dataset_name] --out_folder /mnt/bundlesdf/bundlesdf_[dataset_name]
```

#### 3) (Optional) If you want to draw the oriented bounding box to visualize the pose, similar to our demo
```bash
python run_custom.py --mode draw_pose --out_folder /mnt/bundlesdf/bundlesdf_[dataset_name]
```

pose_visを動画にする
```bash
python png_files2video.py /media/almagest/73B2/kanazawa/datas/milk_data/bundlesdf/bundlesdf_milk_data_20250114_green_bowl/pose_vis -o bundlesdf_milk_data_20250114_green_bowl_pose_vis.mp4
```
