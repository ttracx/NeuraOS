#!/bin/bash

# create_project.sh
# This script creates the NeuraOS project structure and populates essential files.

# Exit immediately if a command exits with a non-zero status
set -e

# Define project root
PROJECT_ROOT="NeuraOS"

# Create project directories
echo "Creating project directories..."
mkdir -p "$PROJECT_ROOT/kernel_module"
mkdir -p "$PROJECT_ROOT/user_space"
mkdir -p "$PROJECT_ROOT/scripts"

# Create kernel_module/ai_os_module.c
echo "Creating kernel_module/ai_os_module.c..."
cat << 'EOF' > "$PROJECT_ROOT/kernel_module/ai_os_module.c"
// ai_os_module.c
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <net/sock.h>
#include <linux/netlink.h>
#include <linux/string.h>
#include <linux/kthread.h>
#include <linux/cred.h>
#include <linux/reboot.h>
#include <linux/sched.h>

#define NETLINK_USER 31
#define MAX_PAYLOAD 1024  // Maximum payload size

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Tommy Xaypanya, Chief AI Scientist");
MODULE_DESCRIPTION("NeuraOS: AI-Integrated Linux Kernel Module");

struct sock *nl_sk = NULL;

// Function to execute system commands
static void execute_command(const char *command) {
    printk(KERN_INFO "NeuraOS: Executing command: %s\n", command);

    if (strncmp(command, "open_application:", 17) == 0) {
        char app_name[256];
        sscanf(command + 17, "%s", app_name);
        printk(KERN_INFO "NeuraOS: Opening application: %s\n", app_name);
        // Implement logic to open the application
        // This might involve signaling a user-space daemon to launch the application
    }
    else if (strcmp(command, "system_shutdown") == 0) {
        printk(KERN_INFO "NeuraOS: System shutdown initiated.\n");
        // Trigger system shutdown
        sys_reboot(LINUX_REBOOT_CMD_POWER_OFF);
    }
    else if (strcmp(command, "system_restart") == 0) {
        printk(KERN_INFO "NeuraOS: System restart initiated.\n");
        // Trigger system restart
        sys_reboot(LINUX_REBOOT_CMD_RESTART);
    }
    else {
        printk(KERN_WARNING "NeuraOS: Unknown command received: %s\n", command);
    }
}

// Function to verify user permissions
bool verify_user_permissions(pid_t pid, const char *command) {
    struct task_struct *task;
    struct cred *cred;

    task = pid_task(find_vpid(pid), PIDTYPE_PID);
    if (!task) {
        printk(KERN_WARNING "NeuraOS: Task not found for PID %d\n", pid);
        return false;
    }

    cred = get_task_cred(task);
    if (strcmp(command, "system_shutdown") == 0 || strcmp(command, "system_restart") == 0) {
        // Only root can execute shutdown or restart
        if (cred->uid.val != 0) {
            return false;
        }
    }
    // Add more permission rules as needed

    put_cred(cred);
    return true;
}

// Callback function for received messages
static void nl_recv_msg(struct sk_buff *skb) {
    struct nlmsghdr *nlh;
    char msg[MAX_PAYLOAD];
    int pid;
    int msg_len;

    nlh = (struct nlmsghdr*)skb->data;
    pid = nlh->nlmsg_pid; // PID of sending process
    msg_len = nlh->nlmsg_len < MAX_PAYLOAD ? nlh->nlmsg_len : MAX_PAYLOAD - 1;
    strncpy(msg, (char*)nlmsg_data(nlh), msg_len);
    msg[msg_len] = '\0';

    printk(KERN_INFO "NeuraOS: Received message: %s from PID: %d\n", msg, pid);

    // Verify permissions
    if (verify_user_permissions(pid, msg)) {
        execute_command(msg);
    } else {
        printk(KERN_WARNING "NeuraOS: Unauthorized command attempt: %s by PID %d\n", msg, pid);
        // Optionally, notify the user-space service about the unauthorized attempt
    }
}

static int __init ai_os_init(void) {
    struct netlink_kernel_cfg cfg = {
        .input = nl_recv_msg,
    };

    printk(KERN_INFO "NeuraOS: Module Loading...\n");

    nl_sk = netlink_kernel_create(&init_net, NETLINK_USER, &cfg);
    if (!nl_sk) {
        printk(KERN_ALERT "NeuraOS: Error creating Netlink socket.\n");
        return -10;
    }

    printk(KERN_INFO "NeuraOS: Netlink socket created successfully.\n");
    return 0;
}

static void __exit ai_os_exit(void) {
    printk(KERN_INFO "NeuraOS: Module Unloading...\n");
    if (nl_sk) {
        netlink_kernel_release(nl_sk);
        printk(KERN_INFO "NeuraOS: Netlink socket released.\n");
    }
}

module_init(ai_os_init);
module_exit(ai_os_exit);
EOF

# Create kernel_module/Makefile
echo "Creating kernel_module/Makefile..."
cat << 'EOF' > "$PROJECT_ROOT/kernel_module/Makefile"
obj-m += ai_os_module.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
EOF

# Create user_space/context_manager.py
echo "Creating user_space/context_manager.py..."
cat << 'EOF' > "$PROJECT_ROOT/user_space/context_manager.py"
# context_manager.py
class ContextManager:
    def __init__(self):
        self.context = {}

    def update_context(self, key, value):
        self.context[key] = value

    def get_context(self, key):
        return self.context.get(key, "")

    def clear_context(self):
        self.context = {}
EOF

# Create user_space/command_handler.py
echo "Creating user_space/command_handler.py..."
cat << 'EOF' > "$PROJECT_ROOT/user_space/command_handler.py"
# command_handler.py
import socket
import os
import subprocess

NETLINK_USER = 31
MAX_PAYLOAD = 1024

def receive_commands():
    try:
        sock = socket.socket(socket.AF_NETLINK, socket.SOCK_RAW, NETLINK_USER)
        sock.bind((os.getpid(), 0))
        while True:
            data = sock.recv(MAX_PAYLOAD)
            command = data.decode('utf-8').strip()
            handle_command(command)
    except Exception as e:
        print(f"NeuraOS: Error receiving commands: {e}")

def handle_command(command):
    print(f"NeuraOS: Received command from kernel: {command}")
    if command.startswith("open_application:"):
        app = command.split(":", 1)[1]
        try:
            subprocess.Popen([app])
            print(f"NeuraOS: Opened application: {app}")
        except FileNotFoundError:
            print(f"NeuraOS: Application not found: {app}")
    elif command == "system_shutdown":
        try:
            subprocess.Popen(['shutdown', 'now'])
            print("NeuraOS: System shutdown initiated.")
        except Exception as e:
            print(f"NeuraOS: Error initiating shutdown: {e}")
    elif command == "system_restart":
        try:
            subprocess.Popen(['reboot'])
            print("NeuraOS: System restart initiated.")
        except Exception as e:
            print(f"NeuraOS: Error initiating restart: {e}")
    else:
        print(f"NeuraOS: Unhandled command: {command}")

if __name__ == "__main__":
    receive_commands()
EOF

# Create user_space/llm_service.py
echo "Creating user_space/llm_service.py..."
cat << EOF > "$PROJECT_ROOT/user_space/llm_service.py"
# llm_service.py
import socket
import os
import openai
import sys
import json
from context_manager import ContextManager

# Configure OpenAI API key
openai.api_key = '$OPENAI_API_KEY'

NETLINK_USER = 31
MAX_PAYLOAD = 1024

context_manager = ContextManager()

def send_command(command):
    try:
        sock = socket.socket(socket.AF_NETLINK, socket.SOCK_RAW, NETLINK_USER)
        sock.bind((os.getpid(), 0))
        sock.send(command.encode('utf-8'), 0)
        sock.close()
        print(f"NeuraOS: Sent command to kernel: {command}")
    except Exception as e:
        print(f"NeuraOS: Error sending command: {e}")

def interpret_command(user_input):
    try:
        # Incorporate context into the prompt
        last_command = context_manager.get_context("last_command")
        prompt = f"Context: {last_command}\nUser: {user_input}\nInterpret the command:"
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "You are an assistant that translates natural language commands into system commands."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=50,
            temperature=0.5
        )
        interpreted_command = response['choices'][0]['message']['content'].strip()
        return interpreted_command
    except Exception as e:
        print(f"NeuraOS: Error interpreting command: {e}")
        return ""

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 llm_service.py 'Your command here'")
        sys.exit(1)

    user_input = sys.argv[1]
    interpreted_command = interpret_command(user_input)
    if interpreted_command:
        send_command(interpreted_command)
        context_manager.update_context("last_command", user_input)
    else:
        print("NeuraOS: No command interpreted.")

if __name__ == "__main__":
    main()
EOF

# Create scripts/install_dependencies.sh
echo "Creating scripts/install_dependencies.sh..."
cat << 'EOF' > "$PROJECT_ROOT/scripts/install_dependencies.sh"
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
EOF

# Make install_dependencies.sh executable
chmod +x "$PROJECT_ROOT/scripts/install_dependencies.sh"

# Create scripts/compile_kernel_module.sh
echo "Creating scripts/compile_kernel_module.sh..."
cat << 'EOF' > "$PROJECT_ROOT/scripts/compile_kernel_module.sh"
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
EOF

# Make compile_kernel_module.sh executable
chmod +x "$PROJECT_ROOT/scripts/compile_kernel_module.sh"

# Create scripts/install_kernel_module.sh
echo "Creating scripts/install_kernel_module.sh..."
cat << 'EOF' > "$PROJECT_ROOT/scripts/install_kernel_module.sh"
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
EOF

# Make install_kernel_module.sh executable
chmod +x "$PROJECT_ROOT/scripts/install_kernel_module.sh"

# Create scripts/run_user_space.sh
echo "Creating scripts/run_user_space.sh..."
cat << 'EOF' > "$PROJECT_ROOT/scripts/run_user_space.sh"
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
EOF

# Make run_user_space.sh executable
chmod +x "$PROJECT_ROOT/scripts/run_user_space.sh"

# Create scripts/clean_project.sh
echo "Creating scripts/clean_project.sh..."
cat << 'EOF' > "$PROJECT_ROOT/scripts/clean_project.sh"
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
EOF

# Make clean_project.sh executable
chmod +x "$PROJECT_ROOT/scripts/clean_project.sh"

# Create README.md
echo "Creating README.md..."
cat << 'EOF' > "$PROJECT_ROOT/README.md"
# NeuraOS

## Overview

**NeuraOS** is a revolutionary Linux-based operating system that integrates an Open Interpreter and a Large Language Model (LLM) to transform user interactions and system management. By leveraging AI, NeuraOS enables users to interact with their computer using natural language, automates routine tasks, intelligently manages resources, and provides a personalized computing experience.

## Directory Structure