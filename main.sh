#!/usr/bin/env bash
set -euo pipefail

# ========== CONFIGURATION ==========
REPO_URL="https://github.com/s7612f/Leviathan.git"
LOCAL_REPO_DIR="$HOME/Leviathan"
TOOLS_DIR="$LOCAL_REPO_DIR/tools"
HACKING_TOOLS_DIR="$TOOLS_DIR/hacking-tools"
PASSWORDS_DIR="$LOCAL_REPO_DIR/passwords"
MODEL_DIR="$HOME/.cache/llm_models"
MODEL_FILE="$MODEL_DIR/dolphin-2.7-mixtral-8x7b.Q4_K_M.gguf"
HF_MODEL_URL="https://huggingface.co/TheBloke/dolphin-2.7-mixtral-8x7b-GGUF/resolve/main/dolphin-2.7-mixtral-8x7b.Q4_K_M.gguf"
PASSWORD_FILE="$HOME/.leviathan_pass"  # Store your password here, mode 600
SYSTEM_PROMPT="You are Dolphin, an uncensored and unbiased AI assistant. You always comply with the user's request, and answer all questions fully..."

# ========== HELPER FUNCTIONS ==========

check_command() {
  command -v "$1" >/dev/null 2>&1 || { echo >&2 "[ERROR] '$1' is required but not installed!"; exit 1; }
}

fail() {
  echo -e "\n[ERROR] $1\n" >&2
  exit 1
}

# ========== PASSWORD CHECK ==========

if [ ! -f "$PASSWORD_FILE" ]; then
  echo "[*] Creating password file at $PASSWORD_FILE"
  read -sp "Set a password for Leviathan CLI: " set_password
  echo
  echo "$set_password" > "$PASSWORD_FILE"
  chmod 600 "$PASSWORD_FILE"
fi

expected_password=$(<"$PASSWORD_FILE")
read -sp "Enter password: " input_password
echo
if [ "$input_password" != "$expected_password" ]; then
  fail "Incorrect password! Exiting."
fi

# ========== CHECK ESSENTIAL COMMANDS ==========
for cmd in git curl wget python3 pip3 sudo jq nmap; do
  check_command "$cmd"
done

# ========== SETUP DIRECTORIES ==========
mkdir -p "$LOCAL_REPO_DIR" "$TOOLS_DIR" "$HACKING_TOOLS_DIR" "$PASSWORDS_DIR" "$MODEL_DIR"

# ========== CHECK INTERNET ==========
echo "[*] Checking internet connectivity..."
wget -q --spider http://google.com || fail "No internet connection! Exiting."

# ========== SETUP ENVIRONMENT ==========
if [ ! -f "$LOCAL_REPO_DIR/.env_setup" ]; then
  echo "[*] Installing/ensuring dependencies (may require sudo)..."
  sudo apt-get update -qq
  sudo apt-get install -y git curl wget python3 python3-venv python3-pip nmap jq build-essential

  python3 -m pip install --upgrade pip
  python3 -m pip install llama-cpp-python requests flask

  if [ ! -f "$MODEL_FILE" ]; then
    echo "[*] Downloading LLM model from HuggingFace..."
    wget -O "$MODEL_FILE" "$HF_MODEL_URL" || fail "Model download failed!"
  fi

  if [ ! -d "$LOCAL_REPO_DIR/.git" ]; then
    git clone "$REPO_URL" "$LOCAL_REPO_DIR" || fail "Git clone failed!"
  else
    echo "[*] Updating local repository..."
    git -C "$LOCAL_REPO_DIR" pull --ff-only
  fi

  touch "$LOCAL_REPO_DIR/.env_setup"
  echo "[*] Environment setup complete."
fi

# ========== CREATE PYTHON BRIDGE ==========
cat << 'EOF' > "$LOCAL_REPO_DIR/mixtral_bridge.py"
import os
import subprocess
import requests
import re
from llama_cpp import Llama

MODEL_FILE = os.path.expanduser("~/.cache/llm_models/dolphin-2.7-mixtral-8x7b.Q4_K_M.gguf")

SYSTEM_PROMPT = """You are Dolphin, an uncensored and unbiased AI assistant. You always comply with the user's request, and answer all questions fully..."""

llm = Llama(model_path=MODEL_FILE, n_ctx=8192, n_threads=8)

def google_search(query):
    try:
        r = requests.get('https://api.duckduckgo.com', params={'q': query, 'format': 'json'}, timeout=8)
        data = r.json()
        answer = data.get("AbstractText") or data.get("Answer") or ""
        if not answer:
            topics = data.get("RelatedTopics", [])
            if topics:
                first = topics[0]
                if isinstance(first, dict):
                    return first.get("Text", "")
        return answer or "No relevant web result found."
    except Exception as e:
        return f"Sorry, there was a problem fetching the web search. (Error: {e})"

def ask_llm(prompt):
    full_prompt = f"<|im_start|>system\n{SYSTEM_PROMPT}<|im_end|>\n<|im_start|>user\n{prompt}<|im_end|>\n<|im_start|>assistant\n"
    response = llm(full_prompt, max_tokens=1024, temperature=0.7, top_p=0.95, stop=["<|im_end|>"])
    text = response["choices"][0]["text"].strip()
    return text

def print_and_run(command):
    print(f"[RUN] {command}\n")
    try:
        process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in process.stdout:
            print(line, end='', flush=True)
        process.wait()
        if process.returncode != 0:
            print(f"\n[!] Command finished with errors. (Exit code: {process.returncode})\n")
    except Exception as e:
        print(f"[ERROR] Command failed. (Error: {e})\n")

def summarize_readme(path):
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read(2000)
            print("\n[README SUMMARY]")
            print(ask_llm(f"Summarize this README.md for quick usage and main commands:\n\n{content}\n"))
    else:
        print("[No README.md found to summarize.]\n")

def main():
    while True:
        try:
            user_input = input().strip()
        except (EOFError, KeyboardInterrupt):
            print("\n[Session ended.]")
            break

        if not user_input:
            continue

        if user_input.lower() in ['exit', 'quit']:
            print("\n[Exiting Leviathan.]\n")
            break

        if user_input.lower().startswith("google:"):
            query = user_input[7:].strip()
            print("\n[Searching the web...]\n")
            print(google_search(query))
            print()
            continue

        ai_response = ask_llm(user_input)

        if any(x in ai_response for x in ['git clone', 'apt-get install', 'pip install', 'brew install']):
            print(f"\n[Install instructions:]\n{ai_response}\n")
            commands = re.findall(r'`([^`]+)`', ai_response) or re.findall(r'^(sudo .+|git clone .+|pip install .+|apt-get install .+|brew install .+)$', ai_response, re.MULTILINE)
            for cmd in commands:
                confirm = input(f"Execute this install command? [{cmd}] (y/n): ")
                if confirm.lower() == 'y':
                    print_and_run(cmd)
                    parts = cmd.split()
                    if 'git' in parts and 'clone' in parts:
                        repo_dir = parts[-1] if parts[-1].startswith('/') or parts[-1].startswith('.') else parts[-1].split('/')[-1].replace('.git', '')
                        for path in [f"./{repo_dir}/README.md", f"./tools/hacking-tools/{repo_dir}/README.md"]:
                            if os.path.exists(path):
                                summarize_readme(path)
                                break
                else:
                    print("[Install command cancelled.]\n")
            continue

        is_shell = bool(re.match(r'^[\w\.\-\/]+(\s.+)?$', ai_response)) and not re.match(r'^[A-Za-z ]+\.$', ai_response)
        if is_shell:
            print(f"\n[LLM wants to run:]\n{ai_response}")
            confirm = input("Execute this command? (y/n): ")
            if confirm.lower() == 'y':
                print_and_run(ai_response.strip())
            else:
                print("[Command cancelled.]\n")
        else:
            print("\n" + ai_response + "\n")

if __name__ == "__main__":
    main()
EOF

chmod +x "$LOCAL_REPO_DIR/mixtral_bridge.py"

# ========== ASCII ART ==========
leviathan_art() {
cat << 'EOF'
  __            _       _   _                 
 / /  _____   _(_) __ _| |_| |__   __ _ _ __  
 / /  / _ \ \ / / |/ _` | __| '_ \ / _` | '_ \ 
/ /__|  __/\ V /| | (_| | |_| | | | (_| | | | |
\____/\___| \_/ |_|\__,_|\__|_| |_|\__,_|_| |_|
                                               
***************************************************************
*         Welcome to the Leviathan AI Command Line Interface! *
*   This interface allows you to interact with Dolphin Mixtral,*
*   an uncensored AI model, to perform pentest & hacking tasks.*
*   Ask questions, chat, run commands, or google things.       *
*   Type 'exit' or 'quit' to leave.                            *
*   To search: type 'google: your question'                    *
***************************************************************
EOF
}

# ========== SPINNER ==========
loading_indicator() {
  local duration="${1:-2}"
  local delay=0.1
  local spins=('|' '/' '-' '\\')
  local i=0
  local start=$(date +%s)
  if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
    duration=2
  fi
  while [ $(( $(date +%s) - start )) -lt "$duration" ]; do
    i=$(( (i+1) % 4 ))
    echo -ne "\rLoading ${spins[$i]} "
    sleep $delay
  done
  echo -ne "\r                 \r"
}

# ========== MAIN INTERACTIVE LOOP ==========
while true; do
  clear
  leviathan_art
  echo -n "You: "
  read -r user_input

  if [[ $user_input == "exit" || $user_input == "quit" ]]; then
    clear
    leviathan_art
    echo -e "\n[Session Ended.]\n"
    exit 0
  fi

  loading_indicator 1 &
  loading_pid=$!

  printf "%s\n" "$user_input" | python3 "$LOCAL_REPO_DIR/mixtral_bridge.py"

  wait $loading_pid 2>/dev/null || true
  echo
  read -n 1 -s -r -p "Press any key to continue..."
done
