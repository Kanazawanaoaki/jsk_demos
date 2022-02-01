# fried-vegetables

野菜炒めを作る．
切る，移す，炒める．

## 切る

河原塚さんので切る？

```
roscd informatized_pr2_knife/euslisp/
```

データを集める部分．
- Random cut to collect data
```
roseus pr2-kitchen_knife-interface.l
(setq *pkki* (instance pr2-kitchen_knife-interface :init))
(send *pkki* :init-cut-pose)
(send *pkki* :grasp-object)
(send *pkki* :test-execute-cut :random1)
```
- record rosbag while cutting
```
roslaunch jsk_kitchen_knife_pr2 record_rosbag.launch
```

