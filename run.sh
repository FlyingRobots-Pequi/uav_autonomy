#!/bin/bash

IMAGE_NAME=uav_autonomy:v1.0

# Allow local connections to the X server for GUI applications in Docker
xhost +local:root

# Setup for X11 forwarding to enable GUI
XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

# Run the Docker container with the selected image and configurations for GUI applications
docker run -it --rm \
    --name uav_autonomy_container \
    --privileged \
    --network=host \
    --ipc=host \
    --pid=host \
    --env="DISPLAY=$DISPLAY" \
    --env="QT_X11_NO_MITSHM=1" \
    --runtime nvidia \
    --env="NVIDIA_VISIBLE_DEVICES=all" \
    --env="NVIDIA_DRIVER_CAPABILITIES=all" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    --env="XAUTHORITY=$XAUTH" \
    --volume="$XAUTH:$XAUTH" \
    --volume /dev/:/dev/ \
    $IMAGE_NAME
