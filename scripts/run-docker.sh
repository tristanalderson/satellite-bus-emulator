#!/bin/bash
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PRJ_DIR=$(refresh_path=$(cd "$SCRIPT_DIR/.." && pwd); echo "$refresh_path")

# Ensure global cache directories exist on host under user ownership
mkdir -p "$HOME/.yocto-global-cache/downloads"
mkdir -p "$HOME/.yocto-global-cache/sstate-cache"

docker run -it --rm \
  -v "$PRJ_DIR":/home/yocto/yocto-build \
  -v "$HOME/.yocto-global-cache/downloads":/home/yocto/yocto-build/build-k26/downloads \
  -v "$HOME/.yocto-global-cache/sstate-cache":/home/yocto/yocto-build/build-k26/sstate-cache \
  -v /opt/nvim-linux-x86_64/:/home/yocto/nvim \
  -v "$HOME/.config/nvim":/home/yocto/.config/nvim \
  -v "$HOME/.tmux.conf":/home/yocto/.tmux.conf \
  -p 5000:5000 -p 50000:50000 \
  satellite-builder:latest
