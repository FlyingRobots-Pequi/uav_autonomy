# From the root of the repository, build the docker image with:
# docker build -t uav_autonomy:latest -f uav_autonomy/docker/Dockerfile .

FROM ros:humble

RUN apt update && apt install -y \
    git \
    nano \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /px4_ws/src && cd /px4_ws/src && \
    git clone -b release/1.15 https://github.com/FlyingRobots-Pequi/px4_msgs.git && \
    cd /px4_ws && \
    . /opt/ros/humble/setup.sh && \
    colcon build --symlink-install

WORKDIR /ros2_ws

COPY ./ros_packages /ros2_ws/src

RUN . /opt/ros/humble/setup.sh && \
    colcon build --symlink-install

COPY ./utils/entrypoint.sh /entrypoint.sh

RUN echo "source /entrypoint.sh" >> /root/.bashrc

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

CMD ["/bin/bash"]