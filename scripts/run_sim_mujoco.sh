#!/usr/bin/env bash
set -euo pipefail

ROBOT="${1:-d1h}"

COLCON_WS="$HOME/d1_ws"
MUJOCO_DIR="$HOME/Dev/mujoco-3.2.7"
ORT_DIR="$HOME/Dev/onnxruntime-linux-x64-1.17.3"

set +u
source /opt/ros/humble/setup.bash
source "$COLCON_WS/install/setup.bash"
set -u

export LD_LIBRARY_PATH="$ORT_DIR/lib:$MUJOCO_DIR/lib:${LD_LIBRARY_PATH:-}"

ros2 launch rl_controller sim_mujoco.launch.py robot:="$ROBOT"
