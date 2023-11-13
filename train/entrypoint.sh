#!/bin/bash -e

USER_ID=$(id -u)
GROUP_ID=$(id -g)

if [ x"$GROUP_ID" != x"0" ]; then
    groupadd -g $GROUP_ID $USER_NAME
fi

if [ x"$USER_ID" != x"0" ]; then
    useradd -d /home/$USER_NAME -m -s /bin/bash -u $USER_ID -g $GROUP_ID $USER_NAME
fi

sudo chown -R $USER_NAME:$USER_NAME /home/$USER_NAME
sudo chmod u-s /usr/sbin/useradd
sudo chmod u-s /usr/sbin/groupadd

exec $@
