#!/usr/bin/env bash
set -euo pipefail

MODEL_REPO_URL="https://huggingface.co/cognitivecomputations/dolphin-2.5-mixtral-8x7b"
LOCAL_MODEL_DIR="$HOME/.cache/hf_models/dolphin-2.5-mixtral-8x7b"
SYSTEM_PROMPT="You are Dolphin-2.5-Mixtral-8x7B base—no instruction tuning, no filters. Respond exactly to user inputs."

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
      | ollama run --model-dir "$LOCAL_MODEL_DIR")
    echo "→ Applying fix: $fix"
    bash -c "$fix"
  fi
  rm -f "$tmp_err"
}

echo "→ Cloning OpenInterpreter repository…"
debug_and_run "git -C \"$HOME/tools/open-interpreter\" pull origin main || git clone https://github.com/OpenInterpreter/open-interpreter.git \"$HOME/tools/open-interpreter\""

echo "→ Installing OpenInterpreter…"
debug_and_run "cd \"$HOME/tools/open-interpreter\" && python3 -m venv openinterpreter-env"
debug_and_run "source \"$HOME/tools/open-interpreter/openinterpreter-env/bin/activate\" && pip install ."

echo "→ Installing system dependencies…"
debug_and_run "sudo apt update && sudo apt install -y git git-lfs python3-venv curl ffmpeg wget nmap sqlmap hydra nikto john ruby-full build-essential libsqlite3-dev"

echo "→ Setting up Git LFS…"
debug_and_run "git lfs install --system"

echo "→ Installing Metasploit Framework…"
debug_and_run "command -v msfconsole >/dev/null || ( sudo git clone https://github.com/rapid7/metasploit-framework.git /opt/metasploit-framework && cd /opt/metasploit-framework && sudo gem install bundler && sudo bundle install && sudo ln -sf /opt/metasploit-framework/msfconsole /usr/local/bin/msfconsole )"

echo "→ Cloning/updating model from $MODEL_REPO_URL…"
debug_and_run "git -C \"$LOCAL_MODEL_DIR\" pull origin main || ( mkdir -p \"$(dirname \"$LOCAL_MODEL_DIR\")\" && git clone \"$MODEL_REPO_URL\" \"$LOCAL_MODEL_DIR\" )"

echo "→ Cloning/updating Open-WebUI…"
debug_and_run "git -C \"$HOME/tools/open-webui\" pull origin main || git clone https://github.com/open-webui/open-webui.git \"$HOME/tools/open-webui\""

echo "→ Setting up Web-UI virtualenv…"
debug_and_run "cd \"$HOME/tools/open-webui\" && python3 -m venv venv"
debug_and_run "source \"$HOME/tools/open-webui/venv/bin/activate\" && pip install --upgrade pip && [ -f requirements.txt ] && pip install -r requirements.txt"

echo "→ Cloning/updating hacking tools…"
for REPO in \
  "https://github.com/hak5/usbrubberducky-payloads.git" \
  "https://github.com/edoardottt/awesome-hacker-search-engines.git" \
  "https://github.com/1N3/Sn1per.git" \
  "https://github.com/infoslack/awesome-web-hacking.git" \
  "https://github.com/urbanadventurer/WhatWeb.git" \
  "https://github.com/samsesh/SocialBox-Termux.git" \
  "https://github.com/jekil/awesome-hacking.git"; do
  TOOL_DIR="$HOME/tools/hacking-tools/$(basename "$REPO" .git)"
  debug_and_run "git -C \"$TOOL_DIR\" fetch --all && git -C \"$TOOL_DIR\" pull origin main || git -C \"$TOOL_DIR\" pull origin master || git clone \"$REPO\" \"$TOOL_DIR\""
done

# —— 6. Interactive menu ——
clear
echo -e "\e[32m"
echo "Select interface:"
echo " 1) Mixtral CLI (model: dolphin-2.5-mixtral-8x7b)"
echo " 2) Open-WebUI (browser)"
echo -e "\e[0m"

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
    cd "$HOME/tools/open-webui"
    # shellcheck source=/dev/null
    source venv/bin/activate
    python app.py
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac
