#!/bin/bash

# ファイル名のリスト
file_list=(
  "20240209-project_t_daily_objects_yanokura"
  "20240209-project_t_daily_objects_yanokura_null"
  "20240210-project_t_daily_objects_kanazawa_20240209"
)

# ファイルごとに処理を実行
for model_name in "${file_list[@]}"
do
  # スクリプトの実行
  rosrun jsk_teaching_object yolo_detect_test.py /home/kanazawa/Downloads/o-nedo-test/selected_eval "/home/kanazawa/Downloads/o-nedo-test/detect_test/${model_name}_detect_test" "../trained_data/yolo8/${model_name}.pt"
done
