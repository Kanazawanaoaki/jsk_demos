# jsk teaching object package

This package provides a simple human teachable function for the robot to recognize objects.

## Install

```
mkdir -p ~/jsk_teaching_object/src
cd ~/jsk_teaching_object/src
git clone --single-branch https://github.com/iory/jsk_demos -b jsk-teaching-object
source /opt/ros/noetic/setup.bash
rosdep update
rosdep install -y -r --from-paths . --ignore-src
catkin build jsk_teaching_object
source devel/setup.bash
```

## Training

Please see https://github.com/iory/jsk_demos/tree/jsk-teaching-object/train

## Run sample trained models.

```
roslaunch jsk_teaching_object sample_object_detection.launch
```

https://user-images.githubusercontent.com/4690682/283469390-c3fa8d42-14e4-4426-b2e4-b8c6fc13e189.mp4
