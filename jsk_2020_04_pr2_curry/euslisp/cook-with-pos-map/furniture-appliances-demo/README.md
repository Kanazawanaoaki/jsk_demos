# furniture-appliances-demo
家具家電の状態遷移を利用するデモを作る．

これをプリミティブと状態遷移図を作って試してみる．

## ihコンロの実行tmp

つまみ&パネル認識launchを立ち上げる
```
roslaunch jsk_2020_02_pr2_curry center_knob_and_panel_rec.launch
```

smach_viewerを立ち上げる
```
rosrun smach_viewer smach_viewer.py
```

状態遷移図を立ち上げる

```
roscd jsk_2020_04_pr2_curry/euslisp/smach-test/furniture-appliances/
roseus ih-stove-smach.l 
(ih-stove-smach)
```

eusのプログラムを実行する
```
roscd jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/furniture-appliances-demo/
roseus ih-use-stove-with-primitives-codes.l
(now-ih-all)
```

## 電子レンジの実行tmp

電子レンジの位置姿勢認識launch
```
roslaunch jsk_2020_02_pr2_curry detect_microwave.launch
```

ドア&パネル認識launchを立ち上げる
```
roslaunch jsk_2020_02_pr2_curry center_0820_ih_panel_reader.launch
```

smach_viewerを立ち上げる
```
rosrun smach_viewer smach_viewer.py
```

状態遷移図を立ち上げる

```
roscd jsk_2020_04_pr2_curry/euslisp/smach-test/furniture-appliances/
roseus microwave-smach.l 
(microwave-smach)
```

eusのプログラムを実行する
```
roscd jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/furniture-appliances-demo/
roseus microwave-with-primitives-codes.l
(now-microwave-all)
```
