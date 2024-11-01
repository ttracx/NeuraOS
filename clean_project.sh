#!/bin/bash

# clean_project.sh
# Cleans the NeuraOS project by removing build artifacts and stopping services.

# Exit immediately if a command exits with a non-zero status
set -e

PROJECT_ROOT="NeuraOS"

echo "Stopping the command handler daemon..."
pkill -f command_handler.py || echo "Command handler daemon not running."

echo "Removing the kernel module..."
rmmod ai_os_module || echo "Kernel module not loaded."

echo "Cleaning build artifacts..."
cd "$PROJECT_ROOT/kernel_module"
make clean

echo "Cleanup completed successfully."
