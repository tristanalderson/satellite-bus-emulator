#!/bin/bash

# This script must be SOURCED: source scripts/init-yocto.sh

if [ "$0" = "$BASH_SOURCE" ]; then
    echo "Error: This script must be sourced, not executed."
    exit 1
fi

source sdk/environment-setup-cortexa72-cortexa53-poky-linux
source satellite-bus/fprime-venv/bin/activate
