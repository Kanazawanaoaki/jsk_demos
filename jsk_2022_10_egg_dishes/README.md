# jsk_2020_10_egg_dishes

レシピからの卵料理デモ

## tmp scripts


### MeCab
```
python3 mecab_file_test.py -f ../recipes/omelette.txt
```
```
python3 mecab_text_test.py -t バターが溶けたら卵をフライパンに注ぐ．
```


### googletrans
```
python3 googletrans_test.py -t 水が沸騰する
```

### GPT-3
```
python3 gpt-3_test.py -k [YOUR API KEY] -t 0.0 -e -p 'Please put "The water boils" in a noun form ending in water.
'
```


### Make prompt
日本語の単語，あるいは英語の単語から(-p 引数)でも対の意味になるpromptを生成できる．
```
python3 make_prompt.py -k [YOUR API KEY] -j 液体になった卵
```

それを複数実行するパターン．
```
python3 test_make_prompt.py -k [YOUR API KEY]
```

## 見学対応デモ
環境を作る．
https://github.com/Kanazawanaoaki/STVLM  
https://github.com/mqcmd196/vision_and_language_ros/tree/main/clip  

azure-kinectが立ち上がっているか確認.
立ち上がっていなかったら，pr1040nをrebootする．

場所の移動．(TODO)

移動後の位置確認．これらがそれなりに動く位置にする．
```
(stop-ih)
(set-before-pour)
(pour-egg-to-pan :already_set t)
```

サーバーPCで認識部分を色々立ち上げる
```
roscd clip_ros_client/../server
bash run_server.sh
```
```
roscd clip_ros_client/launch/
roslaunch clip_ros_client clip_ros.launch host:=localhost port:=8888 INPUT_IMAGE:=/apply_mask_image/output gui:=true
```
```
roslaunch stvlm exec_rec.launch decomp:=true run_rviz:=false
```
rqtで/mask_image_generatorと/rect_added_image_publisherのparamを変更して，画角等を色々調整する．

手元のPCでrvizを立ち上げる
```
roslaunch stvlm rviz.launch
```

動作実行
```
roscd jsk_2022_10_egg_dishes/euslisp
rlwrap roseus egg_cook_butter_sunny-demo.l
(set-demo) ;; before demo
(cook-sunny-demo) ;; exec demo
```