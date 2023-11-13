# jsk teaching object package

This package provides a simple human teachable function for the robot to recognize objects.

## Install

```
mkdir -p ~/jsk_teaching_object/src
cd ~/jsk_teaching_object/src
wstool init
wstool merge https://raw.githubusercontent.com/iory/jsk_demos/teaching-object/jsk_teaching_object/noetic.rosinstall
wstool update
cd ../
source /opt/ros/noetic/setup.bash
rosdep update
rosdep install -y -r --from-paths src --ignore-src
catkin build jsk_teaching_object
source devel/setup.bash
```

### for r8 demo

```bash
sudo apt install -y ros-noetic-rqt-joint-trajectory-controller ros-noetic-joint-trajectory-controller libsdl2-dev libsdl2-2.0-0 qtmultimedia5-dev libqt5serialport5-dev ros-noetic-urg-node
pip3 install gdown
mkdir -p ~/ros/r8/src/jsk-ros-pkg
cd  ~/ros/r8/src/jsk-ros-pkg
git clone https://github.com/iory/jsk_demos -b teaching-object-2023-09-20
cd  ~/ros/r8/src/
cp ~/ros/r8/src/jsk-ros-pkg/jsk_demos/jsk_teaching_object/jsk_r8.rosinstall.noetic .rosinstall
wstool update -t .
source /opt/ros/$ROS_DISTRO/setup.bash
cd ~/ros/r8/src/jsk-ros-pkg/jsk_demos/jsk_teaching_object
rosdep install -y -r --from-paths . --ignore-src
cd ~/ros/r8/src/jsk-ros-pkg/jsk_demos/fg_ros
rosdep install -y -r --from-paths . --ignore-src
cd ~/ros/r8/src/seed-solutions
rosdep install -y -r --from-paths . --ignore-src
cd ~/ros/r8
catkin build jsk_teaching_object r8_5
source ~/ros/r8/devel/setup.bash
sudo cp $(rospack find r8_5)/udev/99-usb-serial.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo mkdir -p /etc/opt/teaching-object/
sudo chmod 777 /etc/opt/teaching-object/
roscd r8_5/model/
xacro r8_5.urdf.xacro > r8_5.urdf
```

## Training

comming soon.

## Run trained models.

```
roslaunch jsk_teaching_object edgetpu_detection.launch INPUT_IMAGE:=/openni_camera/rgb/image_raw \
    model_file:=<MODEL_PATH> \
    label_file:=<LABEL_FILE_PATH>
```

## Run sample trained models.

```
roslaunch jsk_teaching_object sample_edgetpu_detection_with_depth_filter.launch
```

![](./doc/recognition.gif)

### for industry objects

```
roslaunch jsk_teaching_object sample_foreground_detection.launch
```

## Run for r8

```
roscore
```

```
roslaunch r8_5 bringup_minimum.launch
```

```
roslaunch jsk_teaching_object 2023-09-20-all.launch
```

```
roslaunch jsk_teaching_object register_object.launch
```