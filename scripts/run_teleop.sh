#!/usr/bin/env bash
set -euo pipefail

# Drives the sim via raw topic pub, matching the known-working manual sequence:
# transform up -> switch to a policy -> stream a forward velocity command.
POLICY="${1:-rl_4}"          # rl_2 = rl_mjlab_flat (see controllers.yaml rl_policy_names)
FORWARD_VEL="${2:-0.3}"

COLCON_WS="$HOME/d1_ws"

set +u
source /opt/ros/humble/setup.bash
source "$COLCON_WS/install/setup.bash"
set -u

ros2 topic pub --once /command/cmd_key std_msgs/msg/String "{data: 'transform_up'}"
sleep 3
ros2 topic pub --once /command/cmd_key std_msgs/msg/String "{data: '$POLICY'}"
ros2 topic pub -r 10 /command/cmd_twist geometry_msgs/msg/Twist "{linear: {x: $FORWARD_VEL}}"
