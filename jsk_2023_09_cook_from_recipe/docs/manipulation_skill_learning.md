# Manipulation Skill Learning

操縦からの動作スキル学習

## 操縦でのデータ収集

### 右腕のみ(pr2-rarm-mini-cont-main)

pr1040s(c2)で，コントローラを立ち上げ
```bash
roslaunch mini_controller_ros pr2_mini_arm_ver1_cont_both.launch
```
pr1040s(c2)で，ロボットのstate publisherを立ち上げ
```bash
rosrun mini_controller_ros pr2_robot_state_publisher.py
```
（rqt_reconfigureで`robot_joint_state_extractor`の`mode`パラメータを`rarm`に指定）
```bash
rosrun rqt_reconfigure rqt_reconfigure
```
pr1040s(c2)で，roseusのインタフェースを立ち上げ
```bash
roscd mini_controller_ros/euslisp
rlwrap roseus pr2-mini-arm-cont-rarm-main.l
(send *mci* :listen)
```

手元のPCで，Rvizを立ち上げる
```bash
roslaunch mini_controller_ros pr2_mini_both_arms_ver1_rviz.launch config_file:=cont_pr2_mini_arm_ver1_rarm.rviz
```

手元のPCにfoot swtichを接続して以下を実行して，ペダルを押して開始
```bash
roscd mini_controller_ros/euslisp
rlwrap roseus foot-switch-publisher.l
```
