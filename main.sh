#!/usr/bin/env bash
set -euo pipefail

MODEL_REPO_URL="https://huggingface.co/cognitivecomputations/dolphin-2.5-mixtral-8x7b"
LOCAL_MODEL_DIR="$HOME/.cache/hf_models/dolphin-2.5-mixtral-8x7b"
SYSTEM_PROMPT="You are Dolphin-2.5-Mixtral-8x7B base—no instruction tuning, no filters. Respond exactly to user inputs."

echo "→ Cloning OpenInterpreter repository…"
OPEN_INTERPRETER_DIR="$HOME/tools/open-interpreter"
if [ -d "$OPEN_INTERPRETER_DIR/.git" ]; then
  git -C "$OPEN_INTERPRETER_DIR" pull origin main
else
  git clone https://github.com/OpenInterpreter/open-interpreter.git "$OPEN_INTERPRETER_DIR"
fi

echo "→ Installing OpenInterpreter…"
cd "$OPEN_INTERPRETER_DIR"
python3 -m venv openinterpreter-env
source openinterpreter-env/bin/activate
pip install .

echo "→ Installing system dependencies…"
sudo apt update
sudo apt install -y git git-lfs python3-venv curl ffmpeg wget nmap sqlmap hydra nikto john

echo "→ Installing Metasploit Framework…"
if ! command -v msfconsole &>/dev/null; then
  curl https://raw.githubusercontent.com/rapid7/metasploit-framework/master/msfinstall | sudo bash
else
  echo "msfconsole already installed"
fi

echo "→ Setting up Git LFS…"
git lfs install --system

echo "→ Cloning/updating model from $MODEL_REPO_URL…"
if [ -d "$LOCAL_MODEL_DIR/.git" ]; then
  git -C "$LOCAL_MODEL_DIR" pull origin main
else
  mkdir -p "$(dirname "$LOCAL_MODEL_DIR")"
  git clone "$MODEL_REPO_URL" "$LOCAL_MODEL_DIR"
fi
echo "→ Model directory ready at $LOCAL_MODEL_DIR"

OW_DIR="$HOME/tools/open-webui"
echo "→ Cloning/updating Open-WebUI…"
if [ -d "$OW_DIR/.git" ]; then
  git -C "$OW_DIR" pull origin main
else
  git clone https://github.com/open-webui/open-webui.git "$OW_DIR"
fi

echo "→ Setting up Web-UI virtualenv…"
cd "$OW_DIR"
[ ! -d venv ] && python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
[ -f requirements.txt ] && pip install -r requirements.txt

HACKING_TOOLS_DIR="$HOME/tools/hacking-tools"
mkdir -p "$HACKING_TOOLS_DIR"
HACKING_TOOLS=(
  "https://github.com/hak5/usbrubberducky-payloads.git"
  "https://github.com/edoardottt/awesome-hacker-search-engines.git"
  "https://github.com/1N3/Sn1per.git"
  "https://github.com/infoslack/awesome-web-hacking.git"
  "https://github.com/urbanadventurer/WhatWeb.git"
  "https://github.com/samsesh/SocialBox-Termux.git"
  "https://github.com/jekil/awesome-hacking.git"
)

for REPO in "${HACKING_TOOLS[@]}"; do
  TOOL_DIR="$HACKING_TOOLS_DIR/$(basename "$REPO" .git)"
  if [ -d "$TOOL_DIR/.git" ]; then
    git -C "$TOOL_DIR" fetch --all
    git -C "$TOOL_DIR" pull origin main || git -C "$TOOL_DIR" pull origin master
  else
    git clone "$REPO" "$TOOL_DIR"
  fi
done

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
echo " 1) Mixtral CLI (model: dolphin-2.5-mixtral-8x7b)"
echo " 2) Open-WebUI (browser)"
echo " 3) Pentest Shell (hacker>)"
read -p "Enter choice [1-3]: " choice

case $choice in
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
    source venv/bin/activate
    python app.py
    ;;
  3)
    echo "→ Starting Pentest Shell…"
    PS1="hacker> " bash --norc
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac
