#!/usr/bin/env bash
set -euo pipefail

# —— 1. System packages ——
echo "→ Installing system dependencies…"
sudo apt update
sudo apt install -y git python3-venv curl ffmpeg

# —— 2. Ollama CLI & Dolphin-Mixtral ——
if ! command -v ollama &>/dev/null; then
  echo "→ Installing Ollama CLI…"
  curl -fsSL https://ollama.com/install.sh | sh
else
  echo "→ Ollama CLI already installed."
fi

# Ensure ~/.ollama is owned by your user (fixes history permission errors)
if [ -d "$HOME/.ollama" ]; then
  echo "→ Fixing permissions on ~/.ollama…"
  sudo chown -R "$USER":"$USER" "$HOME/.ollama"
fi

if ! ollama list | grep -q "dolphin-mixtral"; then
  echo "→ Pulling Dolphin-Mixtral model…"
  ollama pull dolphin-mixtral:latest
else
  echo "→ Dolphin-Mixtral model already present."
fi

# —— 3. Open-WebUI ——
OW_DIR="$HOME/tools/open-webui"
echo "→ Cloning/updating Open-WebUI…"
if [ -d "$OW_DIR/.git" ]; then
  git -C "$OW_DIR" pull origin main
else
  mkdir -p "$(dirname "$OW_DIR")"
  git clone https://github.com/open-webui/open-webui.git "$OW_DIR"
fi

echo "→ Setting up Web-UI virtualenv…"
cd "$OW_DIR"
if [ ! -d venv ]; then
  python3 -m venv venv
fi
# shellcheck source=/dev/null
source venv/bin/activate
pip install --upgrade pip
if [ -f requirements.txt ]; then
  echo "→ Installing Web-UI Python requirements…"
  pip install -r requirements.txt
fi

# —— 4. Interactive menu ——
echo
echo "Select interface:"
echo " 1) Dolphin CLI"
echo " 2) Open-WebUI"
read -p "Enter choice [1-2]: " choice

case "$choice" in
  1)
    echo "→ Launching Dolphin CLI…"
    ollama run dolphin-mixtral:latest
    ;;
  2)
    echo "→ Starting Open-WebUI…"
    cd "$OW_DIR"
    # shellcheck source=/dev/null
    source venv/bin/activate
    python app.py
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac
