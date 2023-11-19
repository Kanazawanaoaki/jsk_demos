# jsk_2023_09_cook_from_recipe

レシピからの料理デモ

## Setup
```
mkdir -p ~/ros/cooking_ws/src
cd ~/ros/cooking_ws
source /opt/ros/noetic/setup.bash
catkin init
cd ~/ros/cooking_ws/src
git clone git@github.com:Kanazawanaoaki/jsk_demos.git -b sauteed-broccoli-with-butter
cp jsk_demos/jsk_2023_09_cook_from_recipe/rosinstall ./.rosinstall
wstool up
cd ~/ros/cooking_ws/
rosdep install --from-paths --ignore-src -y -r src
catkin b jsk_2023_09_cook_from_recipe
source ~/ros/cooking_ws/devel/setup.bash
```

## exec demo
### prepare
in server pc
```
roslaunch jsk_2023_09_cook_from_recipe cook_rec_for_broccoli.launch
```
and
```
## cd foundations/imagebind_scripts (https://github.com/Kanazawanaoaki/foundations/tree/pr2_cook_broccoli )
python pr2_cook_imagebind_seq.py
```

in exec pc
```
roslaunch jsk_2023_09_cook_from_recipe rviz.launch
```

### move and set env
move
```
roscd jsk_2023_09_cook_from_recipe/euslisp
roseus move-to-coords.l
(move-to-stove-front-ri-direct)
```
You can also check whether robot can operate ih-stove well.
```
roseus sauteed-broccoli-with-butter-demo.l
(start-ih)
(stop-ih)
(start-ih :left t)
(stop-ih :left t)
```
set env
```
roseus sauteed-broccoli-with-butter-demo.l
(set-demo-before) ;; set spatula, pan and pot.
```

If gazing area with (gaze-left-pot) and (gaze-right-pan) is not correct, params should be fixed.

### exec demo
Before exec you should check `rostopic hz /k4a/rgb/image_rect_color/compressed` and if the topic is not come, you should ssh and reboot `pr1040n`.

```
roseus sauteed-broccoli-with-butter-demo.l
(exec-demo)
```
