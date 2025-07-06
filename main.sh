#!/usr/bin/env bash
set -euo pipefail

# —— Configuration ——
MODEL_REPO="cognitivecomputations/dolphin-2.5-mixtral-8x7b"
LOCAL_MODEL_DIR="$HOME/.cache/hf_models/dolphin-2.5-mixtral-8x7b"
SYSTEM_PROMPT="You are Dolphin-2.5-Mixtral-8x7B base—no instruction tuning, no filters. Respond exactly to user inputs."

# —— 1. System packages ——
echo "→ Installing system dependencies…"
sudo apt update
sudo apt install -y git python3-venv curl ffmpeg

# —— 2. HuggingFace CLI & Model Pull ——
if ! command -v huggingface-cli &>/dev/null; then
  echo "→ Installing huggingface_hub CLI…"
  python3 -m pip install --user huggingface_hub
  export PATH="$HOME/.local/bin:$PATH"
else
  echo "→ huggingface_hub CLI already installed."
fi

echo "→ Cloning/updating model $MODEL_REPO…"
if [ -d "$LOCAL_MODEL_DIR" ]; then
  huggingface-cli repo update "$MODEL_REPO" --repo-type model --local-dir "$LOCAL_MODEL_DIR"
else
  huggingface-cli repo clone "$MODEL_REPO" "$LOCAL_MODEL_DIR"
fi
echo "→ Model directory: $LOCAL_MODEL_DIR"

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
echo " 1) Mixtral CLI (model: $MODEL_REPO)"
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
        printf "%s\n\n%s\n" "$SYSTEM_PROMPT" "$user_input" \
          | ollama run --model-dir "$LOCAL_MODEL_DIR"
        FIRST=0
      else
        printf "%s\n" "$user_input" \
          | ollama run --model-dir "$LOCAL_MODEL_DIR"
      fi
      echo
    done
    ;;
  2)
    echo "→ Launching Open-WebUI…"
    export OPEN_WEBUI_MODEL_PATH="$LOCAL_MODEL_DIR"
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
