#!/bin/sh

. /opt/ros/humble/setup.bash
. /px4_ws/install/setup.bash
. /ros2_ws/install/setup.bash

exec "$@"
