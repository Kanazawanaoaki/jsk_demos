# peel-surface-test
皮剥き部分の確認．

## without rec
認識なしの部分．

### potato
じゃがいもの皮剥き部分．

#### potato-first-cut.l
最初に端を切って，断面を使って置く．

```Lisp

```



## with rec
認識あり  

認識用のlaunchを立ち上げる．
```
source ~/semi_ws/devel/setup.bash
roslaunch jsk_2020_04_pr2_curry cutting_board_top_pr2_test.launch
```

### potato
じゃがいもを調理する．

#### potato-cut-first-with-rec.l
じゃがいもの端を切って，立てる．
```
rlwrap roseus potato-cut-first-with-rec.l

(grasp-potato)
(set-knife-hor)
(cut-test)
(finish-pose)
(put-potato)
(reset-larm)
(change-peeler)
```
包丁を掴む所も`(now-devel)`，包丁を掴んでいる状態から`(now-test)`

#### potato-peel-first-with-rec.l
じゃがいもの皮を剥いて，回転させた状態で立てる．  
```
rlwrap roseus potato-peel-first-with-rec.l

(grasp-potato-peel)
(set-potato)
(grasp-peeler)
(peel-test)
(finish-pose-peel)
(put-potato-rotate)
(reset-larm)
```
ピーラーを掴む所も`(now-devel)`，ピーラーを掴んでいる状態から`(now-test)`

### carrot
人参を調理する．

#### carrot-cut-first-with-rec.l
人参の端を切って，立てる．
```
rlwrap roseus carrot-cut-first-with-rec.l

(grasp-carrot)
(set-knife-hor)
(cut-test)
(finish-pose)
(put-carrot)
(reset-larm)
(change-peeler)
```
包丁を掴む所も`(now-devel)`，包丁を掴んでいる状態から`(now-test)`

#### carrot-peel-first-with-rec.l
人参の皮を剥いて，回転させて立てる．
```
rlwrao roseus carrot-peel-first-with-rec.l

(grasp-carrot-peel)
(set-carrot)
(grasp-peeler)
(peel-test)
(finish-pose-peel)
(put-carrot-rotate)
(reset-larm)
```
ピーラーを持つ所も`(now-devel)`，ピーラーを掴んでいる状態から`(now-test)`
