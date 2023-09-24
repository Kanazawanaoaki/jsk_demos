## cook-from-recipe superglue


### 初期位置の保存
```
roslaunch jsk_2023_09_cook_from_recipe pr2_original_image_collection.launch
'''
をした状態で，
```
rosservice call /pr2_original_place_data_collection/save_request
```

### 移動
```
roscd jsk_2023_09_cook_from_recipe/euslisp
roseus move-to-codes.l
```

### 位置調整
launch
```
roslaunch jsk_2023_09_cook_from_recipe original_locate.launch
```
eusの方
```
roscd jsk_2023_09_cook_from_recipe/euslisp
roseus move-to-original-coords.l
(get-current-coords)
(show-camera-coords)
(pr2-move)
```
