# kitchen-move

kitchen move test


## codes
移動：`move-to-kitchen.l`
セットする：`set-object.l`  
じゃがいも：`potato-all.l`  
人参：`carrot-all.l`


## move-to-kitchen
move to kitchen-spot (infront of kitchenboard).

```
roscore
rlwrap roseus move-to-kitchen.l

## go to /eng2/7f/room73B2-front-of-kitchenboard spot
(move-to-kitchenboard-ri)

## go to kitchen-spot original spot
(move-to-kitchen-ri)
```

TODO! need to change target of *ri*

## wipe topboard
```
source ~/semi_ws/devel/setup.bash
roscd jsk_2020_04_pr2_curry/euslisp/kitchen-move
rlwrap roseus wipe-topboard.l

## set wipe
(set-rarm)
## wipe part
(wipe)
## more
(more)

## just to be sure
(one-more)

## after finish
(finish)t
```

## Tabletop grasp test
test tabletop recognition and grasp vegs from above

in gazebo
```
### gazebo launch
source ~/semi_ws/devel/setup.bash
roslaunch table_test_vegs.launch physics:=dart

### tabletop launch
source ~/semi_ws/devel/setup.bash
roslaunch jsk_2020_04_pr2_curry tabletop_test.launch

### euslisp
source ~/semi_ws/devel/setup.bash
roscd jsk_2020_04_pr2_curry/euslisp/kitchen-move
rlwrap roseus table-grasp-from-above.l
```

in real robot
```
### table top launch
source ~/semi_ws/devel/setup.bash
roslaunch jsk_2020_04_pr2_curry tabletop_pr2_test.launch

### euslisp
source ~/semi_ws/devel/setup.bash
roscd jsk_2020_04_pr2_curry/euslisp/kitchen-move
rlwrap roseus table-grasp-from-above.l
```



## peel potato test
test peeling potato by peeler

```
rlwrap roseus peel-potato-code.l

# make potato model
(set-potato :w 90 :l 60 :h 60) # this value should be actual value
# grasp peeler
(set-peeler) # during this part you need to pass the peeler to PR2
# attach left gripper
(set-larm)
# peel move
(peel-test1) # or (peel-test2) for In small increments
# if you want finish
(finish)
```

also exec `(set-peel)` and `(exec-peel)`

## cut potato test
test cutting potato by knife

```
rlwrap roseus cut-potato-code.l

# make potato model
(set-potato :w 90 :l 60 :h 60) # this value should be actual value
# grasp peeler
(set-knife-ver) # during this part you need to pass the knife to PR2
# attach left gripper
(set-larm)
# peel move
(cut-test1) # or (cut-test2) (cut-test3)
# if you want finish
(finish)
```

also exec `(set-cut)` and `(hor-test)` (horizontal grasp)  
there are also util func `(true-coords)` and `(continue-cut 2)`


## cut new test
```
rlwrap roseus cut-new-test-20.l

(set-potato :w 90 :l 60 :h 60)  
(set-knife-ver)
(set-larm) # also (set-larm2)
(cut-test3)

(larm-cut) # also (larm-cut2)

(finish)
```
also exec `(test3)` and `(hor-test)`, `(exec-cut)`.  
there are also util func `(true-coords)` and `(continue-cut 2)`

## peel new test
```
rlwrap roseus peel-new-test-20.l

(set-potato :w 90 :l 60 :h 60)  
(set-peeler)
(set-larm)
(peel-test1)

(finish)
```
also exec `(test1)` and `(test3)`, `(exec-peel)` , `(strong-test)`.  

## carrot new surface test
```
rlwrap roseus carrot-new-surface-test.l

(set-knife-ver)
(set-larm)
(cut-test3)
(move-carrot)
(change-peeler)
(peel-test)
(finish-pose)
(put-carrot)
(next-grasp)
(set-peel)
```
also exec `exec-all` and `next-set`

## surface carrot test
only surface part
```
rlwrap roseus surface-carrot-test.l

(set-larm)
(change-peeler)
(peel-test)
(finish-pose)
(put-carrot)
(next-grasp)
(set-peel)
```

also exec `exec-all` and `next-set`
