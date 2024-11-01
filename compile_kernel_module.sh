#!/bin/bash

# Script to compile the NeuraOS kernel module

# Navigate to the kernel_module directory
cd NeuraOS/kernel_module

# Compile the kernel module
make

# Check if the compilation was successful
if [ -f ai_os_module.ko ]; then
    echo "Kernel module compiled successfully."
else
    echo "Failed to compile the kernel module."
    exit 1
fi