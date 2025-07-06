#!/usr/bin/env bash
set -euo pipefail

# Ensure scripts are executable
chmod +x install.sh install-lite.sh

# Selection menu
echo "Select installation type:"
echo "1. Comprehensive (install.sh)"
echo "2. Lightweight (install-lite.sh)"
read -rp "Enter choice (1/2): " choice

case "$choice" in
  1) ./install.sh ;;
  2) ./install-lite.sh ;;
  *)
    echo "Invalid selection."
    exit 1
    ;;
esac

# Function to handle AI commands via Dolphin Mixtral
handle_ai_command() {
  local cmd="$1"
  response=$(ollama run dolphin-mixtral:8x7b "$cmd")
  echo "AI Response:"
  echo "$response"

  # Optionally execute response if it's a command
  read -rp "Execute response as command? (y/n): " exec_cmd
  if [[ $exec_cmd == "y" ]]; then
    eval "$response"
  fi
}

# Interactive loop to continuously accept commands
while true; do
  read -rp "Enter command (or type 'exit'): " user_input
  [[ $user_input == "exit" ]] && break
  handle_ai_command "$user_input"
done
