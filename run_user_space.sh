#!/bin/bash

# run_user_space.sh
# Starts the NeuraOS user-space services, including the command handler daemon.

# Exit immediately if a command exits with a non-zero status
set -e

PROJECT_ROOT="NeuraOS"

echo "Starting the command handler daemon..."
cd "$PROJECT_ROOT/user_space"
python3 command_handler.py &

COMMAND_HANDLER_PID=$!
echo "NeuraOS: Command handler daemon started with PID: $COMMAND_HANDLER_PID"
echo "To interact with NeuraOS, use the llm_service.py script."
echo "Example:"
echo "python3 llm_service.py 'Open Firefox browser.'"
