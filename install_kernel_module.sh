#!/bin/bash

# install_kernel_module.sh
# Inserts the compiled NeuraOS kernel module into the running kernel.

# Exit immediately if a command exits with a non-zero status
set -e

PROJECT_ROOT="NeuraOS"

echo "Inserting the kernel module..."
cd "$PROJECT_ROOT/kernel_module"
insmod ai_os_module.ko

# Verify module insertion
if lsmod | grep ai_os_module > /dev/null; then
    echo "NeuraOS kernel module inserted successfully."
else
    echo "Failed to insert NeuraOS kernel module."
    exit 1
fi

echo "Recent kernel messages:"
dmesg | tail -n 10
