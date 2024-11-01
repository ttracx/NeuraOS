# llm_service.py
import socket
import os
import openai
import sys
import json
from context_manager import ContextManager

# Configure OpenAI API key
openai.api_key = 'YOUR_OPENAI_API_KEY'

NETLINK_USER = 31
MAX_PAYLOAD = 1024

context_manager = ContextManager()

def send_command(command):
    try:
        sock = socket.socket(socket.AF_NETLINK, socket.SOCK_RAW, NETLINK_USER)
        sock.bind((0, 0))
        nlmsg = command.encode('utf-8')
        sock.send(nlmsg)
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
        print("Usage: python llm_service.py 'Your command here'")
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
