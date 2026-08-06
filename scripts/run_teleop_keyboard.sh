#!/usr/bin/env bash
set -euo pipefail

COLCON_WS="$HOME/d1_ws"

set +u
source /opt/ros/humble/setup.bash
source "$COLCON_WS/install/setup.bash"
set -u

ros2 run keyboard_controller keyboard_controller_node
