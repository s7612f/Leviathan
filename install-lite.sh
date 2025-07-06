#!/usr/bin/env bash
set -euo pipefail

# Install Ollama if not installed
if ! command -v ollama >/dev/null; then
  curl -fsSL https://ollama.com/install.sh | sh
fi

# Pull Dolphin Mixtral model (local)
ollama pull dolphin-mixtral:8x7b

# Install minimal required system dependencies
sudo apt update && sudo apt install -y git curl wget python3 python3-venv

echo "Lite installation completed. Additional tools will download as needed."
