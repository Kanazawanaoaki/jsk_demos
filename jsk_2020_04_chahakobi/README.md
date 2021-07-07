# 茶運びロボット

PR2がお茶を作って持ってきてくれるデモを作る。
お湯をわかせて注げれば、お茶だけでなく、コーヒー、カップラーメン、スープ等にも対応できる。

## 作るデモ
### IRT viewer  
IRT viewer上のデモ。
```
roscd jsk_2020_04_chahakobi/euslisp/demos
roseus irt-demo.l
```

###  kinematics simulater  
運動学シミュレータを使って実機と同じeusのインターフェースで作ったデモ。
```
roscd jsk_2020_04_chahakobi/euslisp/demos
roseus kinematics-demo.l
```

### Gazebo  
物理シミュレーションが大事になりそうな部分について、Gazeboを使ってシミュレーションを行う。

キッチンの環境を立ち上げる。
```
roslaunch jsk_2020_04_chahakobi gazebo_test.launch
```
WIP これから実現するgazeboシミュレーション。
- 73b2の環境を使って行うようにする。
- やかんをglobalなRegistrationからつかむ。
- (干渉などを気にしながら)やかんに水をいれる。
- やかんをもってコップにお湯を注ぐ。

#### ICP Registration
テーブルの上のやかんをICPで認識して掴む。道具の点群情報からRegistrationをして道具の認識を行う。
```
roslaunch jsk_2020_04_chahakobi grasp_kettle.launch

roslaunch jsk_2020_04_chahakobi icp_kettle.launch

roscd jsk_2020_04_chahakobi/euslisp/
roseus grasp-kettle.l
```

#### 点群からモデルを作る
ロボットに道具を持たせて動かしながら点群を撮り、点群をmergeして360°の道具の点群モデルを作る。
```
roslaunch jsk_2020_04_chahakobi table_can.launch

roslaunch jsk_2020_04_chahakobi make_model_auto.launch

roslaunch jsk_2020_04_chahakobi ptcloud2pcd_iemon_auto.launch

roscd jsk_2020_04_chahakobi/euslisp/make-models/
roseus iemon-model-auto.l
```

これで保存された合成点群のPCDファイルからPointCloudを出してattention clipperで一部を切り出す。
```
 roslaunch jsk_2020_04_chahakobi pcd_to_ptcloud_iemon.launch INPUT:="/home/kanazawa/semi_ws/src/jsk_demos/jsk_2020_04_chahakobi/pcd/iemon/iemon_auto_94103000.pcd 0.1"

roslaunch jsk_2020_04_chahakobi ptcloud2pcd_iemon_only.launch
```

保存したpcdファイルを変換する。ファイル名などは適宜変更する。
```
roscd jsk_2020_04_chahakobi/python/
python3 trimesh_test.py ../pcd/iemon/iemon_only.pcd ../stl/iemon_auto.stl
```
出来たSTLファイルを[jsk_model_tools](https://github.com/jsk-ros-pkg/jsk_model_tools#convert-from-cad-manually)を使ってeusモデルに変換する。

##### 点群からモデルを作るを試すやつ
```
roslaunch jsk_2020_04_chahakobi table_can.launch

roslaunch jsk_2020_04_chahakobi make_model_auto.launch
# roslaunch jsk_2020_04_chahakobi make_model_self_filter.launch 
```
を立てて置く。
```
roslaunch jsk_2020_04_chahakobi ptcloud2pcd_debug_iemon.launch
```
でdebug中のポイントクラウドを保存して、
```
roslaunch jsk_2020_04_chahakobi ptcloud2pcd_iemon_auto.launch
```
で完成したポイントクラウドを保存する。途中で切り替えるか一緒にlaunchを立てる必要がある。

###### 片手
```
roscd jsk_2020_04_chahakobi/euslisp/make-models/
rlwrap roseus iemon-model-left.l
```

###### 両手
```
roscd jsk_2020_04_chahakobi/euslisp/make-models/
rlwrap roseus iemon-model-dual.l
```



## デモの流れ

- コンロまで行く (go-to-cook)
- やかんの蓋を取る (open-the-lid)
- やかんを持つ (pick-up-kettle)
- シンクまで移動する (go-to-sink)
- やかんに水を入れる (pour-water)
- コンロの前に行く (go-to-cook2)
- やかんをコンロに置く (put-kettle)
- 蓋を閉じる (close-the-lid)
- コンロをつける (put-on-stove)
- お茶を用意する (prepare-tea)
- お湯が湧くのを待つ (wait-boil)
- コンロを消す (turn-off-stove)
- やかんを持つ (pick-up-kettle2)
- お湯を注ぐ (pour-hot-water)
- やかんを置く (put-kettle2)
- コップを持つ (pick-up-cup)
- 机まで持っていく (go-to-desk)

一つの動作を一つの関数にしてあり、一つ実行すると次に実行する関数がlogにでるようにしてある。  

また、
```lisp
(exec-all)
```
ですべての動作を実行。
```lisp
(now-devel)
```
で今作っている部分の手前までを実行できる。  

## 考えられる改善
最初にお茶やコーヒー、カップラーメンなどを用意してから始めるべき？  
eusのモデルを修正してやかんの蓋を取れるようにする？  
お茶のパックのモデルを作成する？  
お茶やコーヒーの場所をはじめから知っておくべき？そこに無かったら？もし在庫が切れていたら？  
最初に、やかんの向き、お湯が入っているのかどうか、やかんが熱く無いか等を確認する？  
