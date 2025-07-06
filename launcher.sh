#!/usr/bin/env bash
set -e

# —— 1. System packages ——
echo "→ Installing system dependencies…"
sudo apt update
sudo apt install -y git python3-venv build-essential ffmpeg curl

# —— 2. Ollama & Dolphin-Mixtral ——
# Check for Ollama CLI
if ! command -v ollama >/dev/null; then
  echo "→ Ollama not found. Installing Ollama…"
  curl -fsSL https://ollama.com/install.sh | sh
else
  echo "→ Ollama is already installed."
fi

# Check for Dolphin-Mixtral model
# Check for Dolphin-Mixtral model
if ! ollama list | grep -q "dolphin-mixtral"; then
  echo "→ Dolphin-Mixtral model not found. Pulling dolphin-mixtral:latest…"
  ollama pull dolphin-mixtral:latest
else
  echo "→ Dolphin-Mixtral model already present."
fi

# —— 3. Leviathan repo ——
LEVIATHAN_DIR="$HOME/Leviathan"
if [ -d "$LEVIATHAN_DIR/.git" ]; then
  echo "→ Updating Leviathan repo…"
  git -C "$LEVIATHAN_DIR" pull origin main
else
  echo "→ Cloning Leviathan repo…"
  git clone https://github.com/s7612f/Leviathan.git "$LEVIATHAN_DIR"
fi

# —— 4. Open-WebUI setup ——
OW_DIR="$HOME/tools/open-webui"
if [ -d "$OW_DIR/.git" ]; then
  echo "→ Updating Open-WebUI…"
  git -C "$OW_DIR" pull origin main
else
  echo "→ Cloning Open-WebUI…"
  mkdir -p "$(dirname "$OW_DIR")"
  git clone https://github.com/open-webui/open-webui.git "$OW_DIR"
fi

echo "→ Setting up Python venv for Open-WebUI…"
cd "$OW_DIR"
if [ ! -d "venv" ]; then
  python3 -m venv venv
fi
# shellcheck source=/dev/null
source venv/bin/activate
pip install --upgrade pip
if [ -f "requirements.txt" ]; then
  pip install -r requirements.txt
else
  echo "→ requirements.txt not found; skipping Python dependencies installation."
fi

echo
echo "✅  Bootstrap complete!"
echo "   • Leviathan at:    $LEVIATHAN_DIR"
echo "   • Open-WebUI at:   $OW_DIR"
echo "   • Dolphin-Mixtral installed:   $(ollama list | grep dolphin-mixtral || echo 'none')"
