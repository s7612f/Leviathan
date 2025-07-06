#!/usr/bin/env bash
set -euo pipefail

# Install Ollama if not installed
if ! command -v ollama >/dev/null; then
  curl -fsSL https://ollama.com/install.sh | sh
fi

# Pull Dolphin Mixtral model
ollama pull dolphin-mixtral:8x7b

# Install minimal dependencies
sudo apt update && sudo apt install -y git curl wget python3 python3-venv nmap

echo "Lite installation complete. Ready for dynamic tool installation."
