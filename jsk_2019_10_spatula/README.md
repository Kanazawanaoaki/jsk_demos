# PR2 cake demo

## How to use the scraping demo
### 0) preparation
- use custom grippers
- use gloves and aprin for protection of robot
- when you put the gloves, put some tape around the wrist to prevent the glove from slipping
- put the cup at the place according to the tape and put handle in right direction

To use the PR2 cake demo multiple nodes have to be run
### 1) launch launch files for vision
- roslaunch reproduce_pc.launch
- roslaunch passthrough.launch
- roslaunch detect_dirt.launch
### 2) run nodes for force feedback
- rosrun jsk_2019_10_spatula analyze_effort.py
- rosrun jsk_2019_10_spatula compare_force.py
### 3) use lisp programm
- open scrape_bowl.l in editor
- in editor load scrape_bowl.l
- you can run (reset-pose-high) to put the robot in a good position to put on gloves
- run (prepare-robot) to hand robot the spatula and bowl
- run (exec)
- CAUTION robot will move not only with its arms but also performs unsafe movements with the platform

## How to use my version of Murooka-sans microwave demo
### 0) preparation
- remove drawer from cupboard
- put something behind microwave to have microwave up front (e.g. lid of coockies)
- put something in the microwave under the rotating plate to prevent it from rotating (e.g deep plate)
### 1) launch launch file
- detect_microwave.launch
### 2) use lisp programm
- open pr2_interface.l
- run (exec-anne-1st-part)
- in case the vision fails, 
    - run (speak-en "I am sorry I was not able to find the microwave can you give me a second try with a fresh start")
    - use playstation controller to reposition PR2 in a good start position
    - run (send *pmi* :go-to-microwave-accurately)
- run (exec-anne-2nd-part)

# How to use the force publisher
- run analyze_effort.py (this node publishes the force)
- calculate jacobian whenever arm moves for left and right hand as done in (get-jacobi-l-world) and (get-jacobi-r-world)
- publish jacobian in lisp code as done in  (publish-jacobi arm) in scrape_bowl.l
- Force.msg and Jacobian.msg are necessary to use this 




## PR2 Force Test

The goal is to find out how accurate the effort data from PR2 is

### pr2-spatula-force-test.l
- with this little demo PR2 scrapes along a bowl 40 times, which it is holding in its left gripper using a spatula with its right gripper
- the demo does not include picking up the bowl and spatula, PR2 waits 5 seconds before closing one griper at a time, the spatula and bowl have to be placed in the gripper manually

### plot_bag.py, PR2_joints.pdf and bagfiles
- the task was executed three times:
  1. Once as intended with spatula and bowl in both hands.
  2. Once without the bowl
  3. Once without the spatula
  This is used to compare the effort signals with and without contact.
  The effort of the right hand from version 1 is compared to the effort of the right arm version 2.
  The effort of the left hand version one is compared to the effort of the left arm version 3.
  This comparison is used to see if contact can be detected in the effort signals.
  
- the data can then be extracted split and plot with the python file. To do so:
  1. download the bagfiles from the following link: https://drive.google.com/drive/folders/1gq6TnKa5HTYQjAxiZ2W5w2jUel8rgWeL
  2. change the absolute path to the bagfiles in the python file manually
  3. decide in which joint you are interested and put that also manually in the main() of the python file
      PR2_joints.pdf (adapted from the pr2 manual) can be used to find the name of the joint you are interested in: the upper blue names are the joint names used in the python file
  4.) The python script will split the bag file at the position where the scraping movement starts, so that all 40 scraping movements of one bag file are plot on top of each other
  5.) The plot shows the effort in the top and the position in the bottom, by default it also plots crosses in the bottom view, where the scraping movement stopped
      - the experiment with spatula and bowl is plot in red
      - the experiment without spatula is plot in blue
      - the experiment without bowl is plot in green
- the data can also be lowpass filtered if wished, eg. add the argument *cutoff_f = 10* when calling plot_data inside the main() to apply a low pass filter with a cutoff frequency of 10Hz, you can also define the *order* (default is 6) and the sampling rate *fs* (default is 100.3)
- the lowpass filtered data can be plot together with the not fltered data to experiment with different cutoff frequencies
      
