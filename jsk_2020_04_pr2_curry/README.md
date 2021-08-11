# カレー作りロボット

PR2が一般家庭の台所で、一般家庭にある道具を使って、外出中にカレーを作ってくれるデモを作る。

## 作るデモ
### IRT viewer  
まずIRT viewerで作る、認識とかもすべてわかっている状態。シミュレーションでも無い。

###  kinematics simulater  
運動学シミュレータを使って実機と同じeusのインターフェースでデモを作る。

### Gazebo  
物理シミュレーションや認識が大事になりそうな部分について、Gazeboを使ってシミュレーションを行う。

## デモの流れ

大まかな行程  
- 具材、道具の用意
- 具材を洗う
- 具材を切る
- 炒める
- 煮込む
- よそう


一つの動作を一つの関数にしてあり、一つ実行すると次に実行する関数がlogにでるようにする。  

また、
```lisp
(exec-all)
```
ですべての動作を実行。
```lisp
(now-devel)
```
で今作っている部分の手前までを実行できる。  


## gazeno test
gazeboを使ってシミュレーションをする。

### テーブルの上に野菜

```
roslaunch jsk_2020_04_pr2_curry table_vegs.launch
```
```
roslaunch jsk_2020_04_pr2_curry tabletop_test.launch
```
```
roscd jsk_2020_04_pr2_curry/euslisp/
rlwrap roseus gazebo-test.l 
```

# 実機で行う時

## ハードウェアの準備
PR2のグリッパを替える  
PR2の移動  
PR2の手袋+グリッパ部分のカバー  
PR2の


### ソフトウェアの準備

```
roslaunch jsk_2020_04_pr2_curry cutting_board_top_pr2_test.launch 
```

遠隔でやったときは
```
roslaunch jsk_2020_04_pr2_curry rviz_cutting_board_top_pr2_test.launch 
```
でRvizを見るなど


ものによってはdata_collection_serverが必要
```
roslaunch jsk_2020_04_pr2_curry data_collection_prosilica.launch
```
```
roslaunch jsk_2020_04_pr2_curry data_collection_kinect_and_prosilica_each.launch
```


室岡さんの切るやつを使う時
```
roslaunch jsk_kitchen_knife_pr2 execute.launch
```
