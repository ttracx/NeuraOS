#!/bin/bash

# compile_kernel_module.sh
# Compiles the NeuraOS kernel module.

# Exit immediately if a command exits with a non-zero status
set -e

PROJECT_ROOT="NeuraOS"

echo "Compiling the kernel module..."
cd "$PROJECT_ROOT/kernel_module"
make

echo "Kernel module compiled successfully."
