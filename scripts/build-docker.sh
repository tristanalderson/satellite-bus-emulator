#!/bin/bash
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PRJ_DIR="$SCRIPT_DIR/.."

docker build \
  --build-arg USER_ID=$(id -u) \
  --build-arg GROUP_ID=$(id -g) \
  -t satellite-builder:latest "$PRJ_DIR"
