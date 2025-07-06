#!/usr/bin/env bash
set -euo pipefail

# Install Ollama if not installed
if ! command -v ollama >/dev/null; then
  curl -fsSL https://ollama.com/install.sh | sh
fi

# Pull Dolphin Mixtral model (local)
ollama pull dolphin-mixtral:8x7b

# Install common penetration testing tools
sudo apt update && sudo apt install -y git curl wget python3 python3-venv ffmpeg nmap sqlmap hydra nikto john ruby-full build-essential libsqlite3-dev metasploit-framework

# Clone common hacking tools
mkdir -p ~/Leviathan/tools/hacking-tools
cd ~/Leviathan/tools/hacking-tools

tools=(
  "https://github.com/vanhauser-thc/thc-hydra.git"
  "https://github.com/sherlock-project/sherlock.git"
  "https://github.com/urbanadventurer/WhatWeb.git"
  "https://github.com/1N3/Sn1per.git"
)

for tool in "${tools[@]}"; do
  git clone "$tool"
done

echo "Full installation completed."
