#!/bin/bash

# This script installs libraries that cannot be installed from the Arduino IDE GUI.

# Note that every header files (YYY.h) should be placed XXX directory
# XXX directory should be placed under $ARDUINO_LIBRARY_PATH
# For example, $ARDUINO_LIBRARY_PATH/XXX/YYY.h
create_symlink () {
    ORIG_PATH=$1
    SYMLINK_PATH=$2
    if [ -e $SYMLINK_PATH ]; then
        echo "Symlink already exists: $SYMLINK_PATH"
    else
        ln -s $ORIG_PATH $SYMLINK_PATH
        echo "Create symlink $SYMLINK_PATH"
    fi
}

# ARG1: github url (https://github.com/xxx/yyy.git)
# ARG2: Branch, version or commit ID to checkout (optional)
clone_library () {
    CLONE_URL=$1
    PACKAGE_NAME=$(basename $CLONE_URL | cut -f 1 -d '.')
    CLONE_DIR=$HOME/Arduino/libraries/$PACKAGE_NAME
    BRANCH=${2:-0}
    if [ ! -d $CLONE_DIR ]; then
        git clone $CLONE_URL $CLONE_DIR
        if [ $BRANCH != 0 ]; then
            cd $CLONE_DIR
            git checkout -b $BRANCH
            cd -
        fi
    else
        echo "$CLONE_DIR already exists"
    fi
}

ARDUINO_VERSION=${1:-1.8.16}
ARDUINO_LIBRARY_PATH=$HOME/arduino-$ARDUINO_VERSION/libraries

# Create symlink for m5stack_ros/arduino_libraries
ORIG_PATH=$(rospack find jsk_2023_09_cook_from_recipe)/arduino_libraries
SYMLINK_PATH=$ARDUINO_LIBRARY_PATH/jsk_2023_09_cook_from_recipe
create_symlink $ORIG_PATH $SYMLINK_PATH
