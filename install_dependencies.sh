#!/bin/bash

# install_dependencies.sh
# Installs necessary system and Python dependencies required for NeuraOS.

# Exit immediately if a command exits with a non-zero status
set -e

echo "Updating package list..."
apt-get update

echo "Installing build-essential and kernel headers..."
apt-get install -y build-essential linux-headers-$(uname -r)

echo "Installing Python3 and pip3..."
apt-get install -y python3 python3-pip

echo "Installing Python dependencies..."
pip3 install --user openai

echo "All dependencies installed successfully."
