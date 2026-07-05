#!/bin/bash
# This script must be SOURCED: source scripts/init-yocto.sh

if [ "$0" = "$BASH_SOURCE" ]; then
    echo "Error: This script must be sourced, not executed."
    exit 1
fi

source poky/oe-init-build-env build-k26

# Naked execution. No loops, no guards, no variables. 
# If they exist, Yocto notes it and moves on.
bitbake-layers add-layer \
  ../repos/meta-openembedded/meta-oe \
  ../repos/meta-arm/meta-arm-toolchain \
  ../repos/meta-arm/meta-arm \
  ../repos/meta-xilinx/meta-xilinx-core \
  ../repos/meta-xilinx/meta-xilinx-bsp \
  ../repos/meta-xilinx/meta-xilinx-standalone \
  ../repos/meta-xilinx/meta-microblaze \
  ../repos/meta-openamp \
  ../repos/meta-openembedded/meta-python \
  ../repos/meta-openembedded/meta-networking \
  ../repos/meta-openembedded/meta-filesystems \
  ../repos/meta-virtualization \
  ../repos/meta-xilinx/meta-xilinx-standalone-sdt \
  ../repos/meta-kria
