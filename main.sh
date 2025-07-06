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
  "https://github.com/jekil/awesome-hacking.git" \
  "https://github.com/sherlock-project/sherlock.git"; do
  TOOL_DIR="$HOME/tools/hacking-tools/$(basename "$REPO" .git)"
  debug_and_run "git -C \"$TOOL_DIR\" fetch --all && git -C \"$TOOL_DIR\" pull origin main || git -C \"$TOOL_DIR\" pull origin master || git clone \"$REPO\" \"$TOOL_DIR\""
done

# —— Build of Tool Interactions ——
echo "→ Build of Tool Interactions:"
echo "OpenInterpreter will assist in correcting any issues during the installation process."
echo "The AI model (Dolphin-2.5-Mixtral-8x7B) will be used for natural language processing and interaction."
echo "Open-WebUI provides a web-based interface for interacting with the AI model."
echo "Hacking tools include a variety of utilities for penetration testing, web hacking, and social engineering."
echo "Metasploit Framework is a comprehensive penetration testing tool that can be integrated with other tools for advanced attacks."
echo "System dependencies ensure that all tools have the necessary libraries and binaries."
echo "Sherlock is added for finding usernames across social networks, enhancing social engineering capabilities."
