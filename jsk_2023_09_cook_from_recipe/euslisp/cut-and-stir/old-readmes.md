## cut and stir (old)


## 見学のデモ 2024/11/17まで azure kinect (k4a)を使っていたバージョン
### セットアップ
z800で
```bash
roslaunch jsk_2023_09_cook_from_recipe pr2_decompress.launch
roslaunch jsk_2023_09_cook_from_recipe use_k4a_remote.launch
```
TRで立ち上げる
```bash
roslaunch jsk_2023_09_cook_from_recipe cook_rec_for_pot-and-pan.launch
```
手元のPCで立ち上げる
```bash
roslaunch jsk_2023_09_cook_from_recipe kitchen_template_matching_k4a.launch
roslaunch jsk_2023_09_cook_from_recipe pot-and-pan_rviz.launch
# roslaunch jsk_2023_09_cook_from_recipe pot-and-pan_rviz_gen4.launch ## if you use P1 Gen4
```


位置にセットする
```
roscd jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/
rlwrap roseus all-butter-sunny-demo.l
(move-to-spot "stove")
(turn-on-stove frying-pan arm1) ;; これを実行して位置を確認

(prepare-sunny) ;; 物体を設置
```

実行する
```bash
roscd jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/
rlwrap roseus all-butter-sunny-demo.l

(load-spot-offset)
(exec-sunny-all)
```