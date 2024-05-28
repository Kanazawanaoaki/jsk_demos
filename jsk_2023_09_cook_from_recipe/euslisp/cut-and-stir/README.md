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
(move-to-spot "kitchen")
```

### テスト
テストを実行する
