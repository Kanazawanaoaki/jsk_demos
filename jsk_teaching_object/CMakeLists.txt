cmake_minimum_required(VERSION 2.8.3)
project(jsk_teaching_object)

find_package(catkin REQUIRED COMPONENTS
  actionlib
  actionlib_msgs
  catkin_virtualenv
  dynamic_reconfigure
  jsk_data
  std_msgs
)

# ------------------------------------------------------------------------------------
# Download
# ------------------------------------------------------------------------------------

# download and install sample data
add_custom_target(${PROJECT_NAME}_install_sample_data ALL COMMAND python$ENV{ROS_PYTHON_VERSION} ${PROJECT_SOURCE_DIR}/scripts/install_sample_data.py)

# download and install trained data
add_custom_target(${PROJECT_NAME}_install_trained_data ALL COMMAND python$ENV{ROS_PYTHON_VERSION} ${PROJECT_SOURCE_DIR}/scripts/install_trained_data.py)

add_action_files(
  DIRECTORY action
  FILES UpdateModel.action TakeImagePhoto.action TakeAction.action
)

catkin_python_setup()

# Dynamic reconfigure support
generate_dynamic_reconfigure_options(
  cfg/DrawRects.cfg
  cfg/InstanceSegmentation.cfg
)

generate_messages(
  DEPENDENCIES actionlib_msgs std_msgs)

catkin_package(
  CATKIN_DEPENDS message_runtime
  sensor_msgs
  jsk_data
  DEPENDS
  LIBRARIES ${PROJECT_NAME}
)

catkin_generate_virtualenv(
  INPUT_REQUIREMENTS requirements.in
  PYTHON_INTERPRETER python3
  USE_SYSTEM_PACKAGES FALSE
  ISOLATE_REQUIREMENTS FALSE
  CHECK_VENV FALSE
)

file(GLOB SCRIPT_PROGRAMS scripts/*.py)
catkin_install_python(
  PROGRAMS ${SCRIPT_PROGRAMS}
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/scripts/)
file(GLOB NODE_SCRIPTS_FILES node_scripts/*.py)
catkin_install_python(
  PROGRAMS ${NODE_SCRIPTS_FILES}
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)

include_directories(
  ${catkin_INCLUDE_DIRS}
)
