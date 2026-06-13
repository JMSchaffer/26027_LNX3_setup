#!/bin/bash

# Setup configuration for the class folder and Zephyr SDK config
CLASS_FOLDER="$HOME/26027_LNX3"
REQUIRED_ZEPHYR_VERSION="0.17.4"
ZEPHYR_SDK_DIR="/opt"

# ---DO NOT MODIFY BELOW HERE---
echo "Setting up environment for LNX3 Linux Buildroot builds..."
export BR2_EXTERNAL=../buildroot-external-microchip/

echo "Setting up Zephyr build tools..."
export ZEPHYR_SDK_INSTALL_DIR="$ZEPHYR_SDK_DIR/zephyr-sdk-$REQUIRED_ZEPHYR_VERSION"
source "$CLASS_FOLDER/zephyr_workspace/zephyr/zephyr-env.sh"
echo "==============================="
echo "=  LNX3 ENVIRONMENT IS READY  ="
echo "==============================="

