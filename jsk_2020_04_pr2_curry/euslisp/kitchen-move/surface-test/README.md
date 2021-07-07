# surface test
surface test.  

## without rec
codes without recognition.

### potato
progaram for potato.

#### potato-move
grasp and move potato.
```
rlwrap roseus potato-move.l

(set-potato :w width :l length :h height)
(move-potato)
(finish)
```
also exec `(now-devel)` and `(now-test)`.  

#### potato-surface-proto
cut and peel potato first set.  
```
rlwrap roseus potato-surface-proto.l

(set-potato :w width :l length :h height)
(grasp-potato)
(set-knife-hor)
(cut-test3)

(change-peeler)
(peel-test)
(finish-pose)

(put-potato)
(next-grasp)
(set-peel)

(next-set)

(peel-test2)
(finish)
```
also exec `(now-test)` and `(exec-all)`.  

#### potato-rotate
grasp and rotate potato.
```
rlwrap roseus potato-rotate.l

(set-potato :w width :l length :h height)
(move-potato-1)

(rotate-potato)
(finish)
```
also exec `(now-devel)` and `(now-test)`.  

#### potato-surface-second
cut and peel potato second set.
```
rlwrap roseus potato-surface-second.l

(set-potato :w width :l length :h height)
(move-potato-1)
(grasp-potato-second)

(set-knife-hor)
(cut-test3-second)

(change-peeler-second)
(peel-test)
(finish-pose)

(put-potato-second)
(next-grasp-second)
(set-peel)

(next-set)

(peel-test2)  
(finish)
```
also exec `(now-test)` and `(exec-all)`.  

### carrot
progaram for carrot.  

#### carrot-move
grasp and move carrot.
```
rlwrap roseus carrot-move.l

(set-carrot :w width :l length :h height)
(move-carrot)

(finish)
```
also exec `(now-devel)` and `(now-test)`.  

#### carrot-surface-proto
cut and peel carrot first set.  
```
rlwrap roseus carrot-surface-proto.l

(set-carrot :w width :l length :h height)
(grasp-carrot)
(set-knife-hor)
(cut-test3)

(change-peeler)
(peel-pose)
(peel-carrot-test)
(finish-pose)

(put-carrot)
(next-grasp)
(set-peel)

(next-set)

(peel-test2)
(finish)
```
also exec `(now-test)` and `(exec-all)`.  

#### carrot-rotate
grasp and move carrot for second set.
```
rlwrap roseus carrot-rotate.l

(set-carrot :w width :l length :h height)
(move-carrot-1)

(move-carrot)

(finish)
```
also exec `(now-devel)` and `(now-test)`.  

#### carrot-surface-second
cut and peel carrot second set.
```
rlwrap roseus carrot-surface-second.l

(set-carrot :w width :l length :h height)
(move-carrot-1)
(grasp-carrot-second)
(set-knife-hor)
(cut-test3-second)

(change-peeler-second)
(peel-pose)
(peel-carrot-test)
(finish-pose)

(put-carrot-second)
(next-grasp-second)
(set-peel)

(next-set)

(peel-test2)
(finish)
```
also exec `(now-test)` and `(exec-all)`.  

### onion
WIP  
just cut.
```
rlwrap roseus only-cut-test.l

(hor-test)
(cut-test3)
(finish)
```
`(test3)` : 包丁を持った状態で切る所だけ．  


## with rec

codes with recognition.

### potato
progaram for potato.  

play rosbag.  
```
source ~/semi_ws/devel/setup.bash
roslaunch jsk_2020_04_pr2_curry pcd_rosbag_test.launch pcd:=/home/kanazawa/semi_ws/src/jsk_demos/jsk_2020_04_pr2_curry/pcd/potato_on_board_0708.pcd
```
cutting board top recog.
```
source ~/semi_ws/devel/setup.bash
roslaunch jsk_2020_04_pr2_curry cutting_board_top_pcd.launch
```

#### potato-move-with-rec
grasp and move potato.
```
rlwrap roseus potato-move-with-rec.l

(move-potato)
(finish)
```
also exec `(now-devel)` and `(now-test)`.  

#### potato-surface-proto-with-rec
cut and peel potato first set.
```
rlwrap roseus potato-surface-proto-with-rec.l

(grasp-potato)
(set-knife-hor)
(cut-test3)

(change-peeler)
(peel-test)
(finish-pose)

(put-potato)
(next-grasp)
(set-peel)

(next-set)

(peel-test2)
(finish)
```
also exec `(now-test)` and `(exec-all)`.

#### potato-rotate-with-rec
grasp and rotate potato.
```
rlwrap roseus potato-rotate-with-rec.l

(rotate-potato)
(finish)
```
also exec `(now-devel)` and `(now-test)`.  

#### potato-surface-second-with-rec
cut and peel potato second set.
```
rlwrap roseus potato-surface-second-with-rec.l

(grasp-potato-second)

(set-knife-hor)
(cut-test3-second)

(change-peeler-second)
(peel-test)
(finish-pose)

(put-potato-second)
(next-grasp-second)
(set-peel)

(next-set)

(peel-test2)  
(finish)
```
also exec `(now-test)` and `(exec-all)`.  

### carrot
progaram for carrot.  

play rosbag.  
```
source ~/semi_ws/devel/setup.bash
roslaunch jsk_2020_04_pr2_curry pcd_rosbag_test.launch pcd:=/home/kanazawa/semi_ws/src/jsk_demos/jsk_2020_04_pr2_curry/pcd/carrot_on_board_2_0708.pcd
```
cutting board top recog.
```
source ~/semi_ws/devel/setup.bash
roslaunch jsk_2020_04_pr2_curry cutting_board_top_pcd.launch
```

#### carrot-move-with-rec
grasp and move carrot.
```
rlwrap roseus potato-move-with-rec.l

(move-carrot)

(finish)
```
also exec `(now-devel)` and `(now-test)`.  

#### carrot-surface-proto-with-rec
cut and peel potato first set.
```
rlwrap roseus carrot-surface-proto-with-rec.l

(grasp-carrot)
(set-knife-hor)
(cut-test3)

(change-peeler)
(peel-test)
(finish-pose)

(put-carrot)
(next-grasp)
(set-peel)

(next-set)

(peel-test2)
(finish)
```
also exec `(now-test)` and `(exec-all)`.  

#### carrot-rotate-with-rec
grasp and rotate carrot.
```
rlwrap roseus carrot-rotate-with-rec.l

(move-carrot)
(finish)
```
also exec `(now-devel)` and `(now-test)`.  

#### carrot-surface-second-with-rec.l
cut and peel carrot second set.
```
rlwrap roseus carrot-surface-second-with-rec.l

(grasp-carrot-second)
(set-knife-hor)
(cut-test3-second)

(change-peeler-second)
(peel-pose)
(peel-carrot-test)
(finish-pose)

(put-carrot-second)
(next-grasp-second)
(set-peel)

(next-set)

(peel-test2)
(finish)
```
also exec `(now-test)` and `(exec-all)`.  
