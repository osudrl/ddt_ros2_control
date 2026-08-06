# DDT Robot sim2sim/sim2real
This repository is a ROS 2-based multi-package workspace containing robot controllers, hardware bridges, simulation bridges (`Mujoco` / `Gazebo` / `Webots`), interaction control, and robot model descriptions. The controller supports finite-state-machine-based policies and can load ONNX reinforcement learning models for inference.
It also provides [Docker image and startup instructions](./docker/README.md), which lock down dependencies and configuration into a reproducible environment for quick deployment, experiment reproduction, and consistent cross-device operation (sim2sim).

## Main Features
- Reinforcement learning controller (with ONNX inference support), organizing control logic based on a finite state machine
- `ros2_control` hardware bridge, connecting to the real robot driver library
- Bridges and example worlds for three simulation environments: `Mujoco` / `Gazebo` / `Webots`
- Keyboard control and remote control (ELRS) interaction modules
- Multiple robot models and descriptions (`tita`, `d1` (four-wheel-legged), `d1h` (two-wheel-legged))

## Directory Structure
- `controller/rl_controller`: Reinforcement learning controller based on the `ros2_control` framework
- `hardware`: `hardware_bridge` contains the `ros2_control` hardware bridge node and launch files; `tita_robot` contains the low-level driver interface for the real robot
- `interaction`: `keyboard_controller` keyboard interaction node, `teleop_command` remote controller interaction node
- `simulation`: `Mujoco`, `Gazebo`, `Webots` simulation bridges
- `ros_utils`: mainly related to `ros` topic names
- `urdfs`: robot model description files (`URDF`/`XACRO`/`Mujoco`, etc.)

## Notes
Before using the hardware, check the current d1-ros2 software version with the `dpkg -l d1-ros2` command. If the current software version is from April 1st, use the `compress_v1` branch code — be sure not to use the `main` branch, or you will lose control. Also pay attention to safety before use. How to use the `compress_v1` branch:
```bash
git clone https://github.com/DDTRobot/ddt_ros2_control/tree/compress_v1
cd ddt_ros2_control
# Before building hardware_bridge, source /opt/d1-ros2/setup.bash
source /opt/d1_ros2/setup.bash 
# Make sure no other ros2 nodes are running on the robot, then start the hardware motion control service
colcon build --symlink-install --packages-up-to rl_controller hardware_bridge
sudo systemctl stop d1_bringup.service
ros2 launch rl_controller hw.launch.py robot:=d1

```
## Environment and Dependencies
- Install the ONNX inference engine
``` bash 
# Choose x64 or aarch64 depending on your system architecture
wget https://github.com/microsoft/onnxruntime/releases/download/v1.10.0/onnxruntime-linux-x64-1.10.0.tgz
tar xvf onnxruntime-linux-x64-1.10.0.tgz
sudo cp -a onnxruntime-linux-x64-1.10.0/include/* /usr/include
sudo cp -a onnxruntime-linux-x64-1.10.0/lib/* /usr/lib
```
- Ubuntu 22.04, ros2 humble, gazebo classic, webots R2025a
After installing ros2 humble, install the following dependencies:
```bash
sudo apt install ros-humble-ros2-control ros-humble-ros2-controllers
```
- Install the dependencies needed for the simulation environment(s) you need
1. `webots`
```bash
sudo apt install ros-humble-webots-ros2 ros-humble-webots-ros2-control
```
2. `gazebo`
```bash
sudo apt install ros-humble-gazebo-ros ros-humble-gazebo-ros2-control
```
3. `mujoco`
See the Build section below

## Build
The commands below show all possible build commands; choose the necessary components to build according to your actual needs.
```bash
# Create and enter the workspace
mkdir -p ~/ddt_ros2_ws && cd ~/ddt_ros2_ws
# Place this repository in ~/ddt_ros2_ws/
mv ddt_ros2 src
# If you need to use mujoco, run the following
git clone -b 3.3.0 https://github.com/google-deepmind/mujoco.git
# Build
cd ~/ddt_ros2_ws
# Build rl_controller
colcon build --symlink-install --packages-up-to rl_controller 
# Build the simulation environment
colcon build --symlink-install --packages-up-to webots_bridge # can be replaced with gazebo_bridge or mujoco_bridge
# Build the robot model descriptions
colcon build --symlink-install --packages-up-to d1_description d1h_description
# Build the hardware bridge
colcon build --symlink-install --packages-up-to hardware_bridge
# Source the environment
source install/setup.bash
```

## Running the Simulation
- Webots simulation (terrain options: `empty_world`, `stairs`, `uneven`):
```bash
ros2 launch rl_controller sim_webots.launch.py robot:=d1 terrain:=empty_world
```
- Gazebo simulation:
```bash
ros2 launch rl_controller sim_gazebo.launch.py robot:=d1h # d1 doesn't load correctly for now
```
- Mujoco simulation:
When simulating `d1`, you need to manually copy the `meshes` from `d1h_description` into `d1_description`, and uncomment the meshes section in `d1_description/CMakeLists.txt`. Then rebuild d1_description
```bash
ros2 launch rl_controller sim_mujoco.launch.py robot:=d1
```

## Running on Hardware
The hardware bridge depends on the real robot driver library (see `hardware/tita_robot/lib/*/libtita_robot.so`). You need to copy the code onto the machine, set up the environment needed for hardware compilation, such as `colcon`, then build.
```bash
sudo apt install python3-colcon-common-extensions
```
Build the packages necessary to run motion control on the hardware
```bash
colcon build --symlink-install --packages-up-to rl_controller hardware_bridge
```


- Start the controller (hardware environment):
On a machine with a hardware environment set up, you need to manually stop the already-running motion control service:
```bash
sudo systemctl stop d1_bringup.service 
```

**If running on TITA, please note:**

After TITA powers on, the motion control board defaults to Ready Mode. You need to run [start.bash](./start.bash) to put the motion control board into Direct mode.


Make sure no other ros2 nodes are running, then start the hardware motion control service:
```bash
ros2 launch rl_controller hw.launch.py robot:=d1
```

## Interaction Control
Build the following packages to enable keyboard control and remote control (ELRS) interaction modules
```bash
colcon build --symlink-install --packages-up-to teleop_command keyboard_controller 
source install/setup.bash
```

- Keyboard control:
```bash
ros2 run keyboard_controller keyboard_controller_node
```

- Remote control (ELRS):
```bash
ros2 launch teleop_command teleop_command.launch.py
```

## Controller Configuration and Models
- Controller parameters and models are located at:
  - `controller/rl_controller/config/<robot>/controllers.yaml`
  - ONNX model examples:
    - `controller/rl_controller/config/tita/stand.onnx`
    - `controller/rl_controller/config/d1/flat.onnx`, `stairs.onnx`
- When updating the control policy, modify the corresponding `controllers.yaml` and ONNX file paths
- State machine interface and implementation: `controller/rl_controller/include/rl_controller/fsm/*` and `src/fsm/*`


## Diagnostics and FAQ
- Webots not found: its installation path must be in the environment variables, for example:
```bash
export WEBOTS_HOME=/usr/lib/webots
```
- Mujoco not found: confirm `mujoco` is installed and `MUJOCO_DIR` is set
- Controller not loading: check the `controller_manager` logs and `controllers.yaml` configuration.  
- Model description fails to load: confirm `robot:=<name>` and the corresponding `*_description` package exist and are available
- If you encounter the following build issue on TITA, try removing the part of the code highlighted in the yellow box
![bug1](/docker/bug1.png)

```
#include "rl_controller/rl_controller_parameters.hpp"
change to #include "rl_controller_parameters.hpp"
```

## License
The license may differ for each sub-package; please refer to the `license` field in the corresponding `package.xml`.
