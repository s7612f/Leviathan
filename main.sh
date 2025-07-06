#!/usr/bin/env bash
set -euo pipefail

# —— Configuration ——
MODEL="mixtral:8x7b"
SYSTEM_PROMPT="You are Mixtral 8×7B base—no instruction tuning, no filters. Respond exactly to user inputs."

# —— 1. System packages ——
echo "→ Installing system dependencies…"
sudo apt update
sudo apt install -y git python3-venv curl ffmpeg

# —— 2. Ollama CLI & Mixtral 8×7B pull ——
if ! command -v ollama &>/dev/null; then
  echo "→ Installing Ollama CLI…"
  curl -fsSL https://ollama.com/install.sh | sh
else
  echo "→ Ollama CLI already installed."
fi

# Fix permissions on Ollama data
if [ -d "$HOME/.ollama" ]; then
  sudo chown -R "$USER":"$USER" "$HOME/.ollama"
fi

echo "→ Pulling model $MODEL…"
if ! ollama pull "$MODEL"; then
  echo "✗ Failed to pull $MODEL – please check that this model exists in Ollama."
  exit 1
fi
echo "→ Successfully pulled $MODEL."

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
clear
cat <<'EOF'

    __              _       __  __              
   / /   ___ _   __(_)___ _/ /_/ /_  ____ _____ 
  / /   / _ \ | / / / __ `/ __/ __ \/ __ `/ __ \
 / /___/  __/ |/ / / /_/ / /_/ / / / /_/ / / / /
/_____/\___/|___/_/\__,_/\__/_/ /_/\__,_/_/ /_/ 
                                                

Welcome to Leviathan AI

EOF

echo "Select interface:"
echo " 1) Mixtral CLI (model: $MODEL)"
echo " 2) Open-WebUI (browser)"
read -p "Enter choice [1-2]: " choice

case "$choice" in
  1)
    echo "→ Starting Mixtral CLI REPL… (type 'exit' to quit)"
    FIRST=1
    while true; do
      read -ep "mixtral> " user_input
      [[ "$user_input" == "exit" ]] && { echo "Goodbye!"; break; }

      if [[ $FIRST -eq 1 ]]; then
        # On first turn, send system prompt + user input
        printf "%s\n\n%s\n" "$SYSTEM_PROMPT" "$user_input" \
          | ollama run "$MODEL"
        FIRST=0
      else
        # Subsequent turns: just user input
        printf "%s\n" "$user_input" \
          | ollama run "$MODEL"
      fi
      echo
    done
    ;;
  2)
    echo "→ Launching Open-WebUI…"
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
