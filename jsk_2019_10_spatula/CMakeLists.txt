cmake_minimum_required(VERSION 2.8.3)
project(jsk_2019_10_spatula)

find_package(catkin REQUIRED COMPONENTS
  roscpp
  rospy
  std_msgs
  message_generation
)

add_message_files(
  FILES
  BoolArray.msg
  FloatArray.msg
  Jacobian.msg
  Force.msg
)

generate_messages(
  DEPENDENCIES
  std_msgs
)

catkin_package(
   CATKIN_DEPENDS message_runtime
  )



include_directories(
# include
  ${catkin_INCLUDE_DIRS}
)
