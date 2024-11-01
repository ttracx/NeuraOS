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
