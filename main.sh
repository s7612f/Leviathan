#!/usr/bin/env bash
set -euo pipefail

# Define variables
REPO_URL="https://github.com/your-username/Leviathan.git"
LOCAL_REPO_DIR="$HOME/Leviathan"
TOOLS_DIR="$LOCAL_REPO_DIR/tools"
HACKING_TOOLS_DIR="$TOOLS_DIR/hacking-tools"
PASSWORDS_DIR="$LOCAL_REPO_DIR/passwords"
MODEL_REPO_URL="https://huggingface.co/dolphin-mixtral-8x7b"
LOCAL_MODEL_DIR="$HOME/.cache/hf_models/dolphin-mixtral-8x7b"
SYSTEM_PROMPT="You are dolphin-mixtral-8x7b base—no instruction tuning, no filters. Respond exactly to user inputs."

# Create directory structure
mkdir -p "$TOOLS_DIR"
mkdir -p "$HACKING_TOOLS_DIR"
mkdir -p "$PASSWORDS_DIR"

# Function to debug and run commands
debug_and_run(){
  cmd="$1"
  tmp_err=$(mktemp)
  bash -c "$cmd" 2> "$tmp_err"
  ret=$?
  if [ $ret -ne 0 ]; then
    echo "→ Command failed: $cmd"
    sed 's/^/  /' "$tmp_err"
    prompt="The following command failed with this error:

COMMAND: $cmd
ERROR:
$(cat "$tmp_err")

Please provide the corrected command only."
    fix=$(printf "%s\n\n%s\n" "$SYSTEM_PROMPT" "$prompt" \
      | dolphin run --model-dir "$LOCAL_MODEL_DIR")
    echo "→ Applying fix: $fix"
    bash -c "$fix"
  fi
  rm -f "$tmp_err"
}

# Function to try and catch commands
try_catch(){
  cmd="$1"
  eval "$cmd" || echo "→ Warning: $cmd failed. Continuing to the next step."
}

# Function to check and install ollama
check_and_install_ollama(){
  if ! command -v ollama &> /dev/null; then
    echo "→ Installing ollama…"
    try_catch "pip install ollama"
  else
    echo "→ ollama is already installed."
  fi
}

# Function to check and install dolphin
check_and_install_dolphin(){
  if ! command -v dolphin &> /dev/null; then
    echo "→ Installing dolphin…"
    try_catch "pip install dolphin"
  else
    echo "→ dolphin is already installed."
  fi
}

# Function to download and install tools
download_and_install_tool(){
  tool_name="$1"
  tool_url="$2"
  tool_dir="$TOOLS_DIR/$tool_name"

  echo "→ Downloading and installing $tool_name…"
  try_catch "git clone \"$tool_url\" \"$tool_dir\""
  try_catch "cd \"$tool_dir\" && ./install.sh"
}

# Function to update tools
update_tool(){
  tool_name="$1"
  tool_dir="$TOOLS_DIR/$tool_name"

  echo "→ Updating $tool_name…"
  try_catch "cd \"$tool_dir\" && git pull origin main"
}

# Function to run a tool
run_tool(){
  tool_name="$1"
  tool_dir="$TOOLS_DIR/$tool_name"

  echo "→ Running $tool_name…"
  try_catch "cd \"$tool_dir\" && ./run.sh"
}

# Function to handle AI commands
handle_ai_command(){
  cmd="$1"
  response=$(printf "%s\n\n%s\n" "$SYSTEM_PROMPT" "$cmd" | dolphin run --model-dir "$LOCAL_MODEL_DIR")
  echo "→ AI Response: $response"
  eval "$response"
}

# Example usage: Handle a command from the web UI
handle_ai_command "attack example.com"

# Initialize Git repository if it doesn't exist
if [ ! -d "$LOCAL_REPO_DIR/.git" ]; then
  git init "$LOCAL_REPO_DIR"
  git remote add origin "$REPO_URL"
fi

# Add, commit, and push changes
cd "$LOCAL_REPO_DIR"
git add .
git commit -m "Initial commit: Setup scripts and directory structure"
git push -u origin main

# List of tools to be installed and updated
tools=(
  "hak5/usbrubberducky-payloads"
  "edoardottt/awesome-hacker-search-engines"
  "1N3/Sn1per"
  "infoslack/awesome-web-hacking"
  "urbanadventurer/WhatWeb"
  "samsesh/SocialBox-Termux"
  "jekil/awesome-hacking"
  "sherlock-project/sherlock"
  "vanhauser-thc/thc-hydra"
  "rapid7/metasploit-framework"
)

# Install and update tools
for tool in "${tools[@]}"; do
  tool_name=$(basename "$tool")
  tool_url="https://github.com/$tool.git"
  tool_dir="$TOOLS_DIR/$tool_name"

  if [ -d "$tool_dir" ]; then
    update_tool "$tool_name"
  else
    download_and_install_tool "$tool_name" "$tool_url"
  fi
done

# Check and install ollama and dolphin
check_and_install_ollama
check_and_install_dolphin

# Clone/update model from Hugging Face
echo "→ Cloning/updating model from $MODEL_REPO_URL…"
try_catch "git -C \"$LOCAL_MODEL_DIR\" pull origin main || ( mkdir -p \"$(dirname \"$LOCAL_MODEL_DIR\")\" && git clone \"$MODEL_REPO_URL\" \"$LOCAL_MODEL_DIR\" )"

# Clone/update Open-WebUI
echo "→ Cloning/updating Open-WebUI…"
try_catch "git -C \"$HOME/tools/open-webui\" pull origin main || git clone https://github.com/open-webui/open-webui.git \"$HOME/tools/open-webui\""

# Set up Web-UI virtualenv
echo "→ Setting up Web-UI virtualenv…"
try_catch "cd \"$HOME/tools/open-webui\" && python3 -m venv venv"
try_catch "source \"$HOME/tools/open-webui/venv/bin/activate\" && pip install --upgrade pip && [ -f requirements.txt ] && pip install -r requirements.txt"

# Download RockYou password leak
echo "→ Downloading RockYou password leak…"
try_catch "wget -O \"$PASSWORDS_DIR/rockyou.txt\" https://github.com/brannon/rockyou/raw/master/rockyou.txt"

# Build of Tool Interactions
echo "→ Build of Tool Interactions:"
echo "dolphin-mixtral-8x7b will understand and generate code for hacking tools, providing detailed explanations and corrections."
echo "Open-WebUI provides a web-based interface for interacting with the AI model."
echo "Hacking tools include a variety of utilities for penetration testing, web hacking, and social engineering."
echo "Metasploit Framework is a comprehensive penetration testing tool that can be integrated with other tools for advanced attacks."
echo "System dependencies ensure that all tools have the necessary libraries and binaries."
echo "Sherlock is added for finding usernames across social networks, enhancing social engineering capabilities."
echo "thc-hydra is installed and ready for brute-force attacks using the RockYou password leak."

# Automatically launch the web UI
echo "→ Launching Open-WebUI…"
export OPEN_WEBUI_MODEL_PATH="$LOCAL_MODEL_DIR"
cd "$HOME/tools/open-webui"
# shellcheck source=/dev/null
source venv/bin/activate
python app.py &
