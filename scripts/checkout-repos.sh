#!/bin/bash
# Fail immediately if any clone fails
set -e

# Determine script directory to allow execution from anywhere
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
TARGET_DIR="$SCRIPT_DIR/../repos"

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

echo "Checking out Yocto and layer repositories..."

git clone -b scarthgap https://github.com/yoctoproject/poky.git
git clone -b scarthgap https://github.com/openembedded/meta-openembedded.git
git clone -b rel-v2024.2 https://github.com/Xilinx/meta-kria.git
git clone -b rel-v2024.2 https://github.com/Xilinx/meta-xilinx.git
git clone -b scarthgap https://github.com/jonmason/meta-arm.git
git clone -b scarthgap https://github.com/Xilinx/meta-virtualization.git
git clone -b scarthgap https://github.com/Xilinx/meta-openamp.git

echo "All repositories cloned successfully into $TARGET_DIR."
