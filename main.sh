#!/usr/bin/env bash
set -euo pipefail

# —— 0. Remove malformed Docker source if present ——
if [ -f /etc/apt/sources.list.d/docker.list ]; then
  if grep -q '[$]' /etc/apt/sources.list.d/docker.list; then
    echo "→ Removing malformed /etc/apt/sources.list.d/docker.list…"
    sudo rm /etc/apt/sources.list.d/docker.list
  fi
fi

# —— 1. System dependencies ——
echo "→ Installing system dependencies…"
sudo apt update
sudo apt install -y \
  apt-transport-https ca-certificates curl gnupg lsb-release \
  git python3-pip python3-venv build-essential ffmpeg

# —— 2. Docker ——
if ! command -v docker &>/dev/null; then
  echo "→ Installing Docker…"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io
  sudo usermod -aG docker "$USER"
else
  echo "→ Docker already installed."
fi

# —— 3. Ollama CLI & Dolphin model ——
if ! command -v ollama &>/dev/null; then
  echo "→ Installing Ollama CLI…"
  curl -fsSL https://ollama.com/install.sh | sh
else
  echo "→ Ollama CLI already installed."
fi

if ! ollama list | grep -q "dolphin-mixtral"; then
  echo "→ Pulling Dolphin-Mixtral model…"
  ollama pull dolphin-mixtral:latest
else
  echo "→ Dolphin-Mixtral model already present."
fi

# —— 4. Leviathan repo ——
REPO="$HOME/Leviathan"
echo "→ Cloning/updating Leviathan…"
if [ -d "$REPO/.git" ]; then
  git -C "$REPO" pull origin main
else
  git clone git@github.com:s7612f/Leviathan.git "$REPO"
fi

# —— 5. Open-WebUI repo ——
OW="$HOME/tools/open-webui"
echo "→ Cloning/updating Open-WebUI…"
if [ -d "$OW/.git" ]; then
  git -C "$OW" pull origin main
else
  mkdir -p "$(dirname "$OW")"
  git clone https://github.com/open-webui/open-webui.git "$OW"
fi

# —— 6. Ollama Docker container ——
echo "→ Ensuring Ollama Docker container…"
if sudo docker ps -a --format '{{.Names}}' | grep -q '^leviathan$'; then
  echo "→ Ollama container already exists."
else
  echo "→ Pulling & running Ollama container…"
  sudo docker pull ollama/ollama:latest
  sudo docker run -d \
    --gpus all \
    -p 11434:11434 \
    --name leviathan \
    -v ~/.ollama:/root/.ollama \
    ollama/ollama:latest

  echo "→ Installing pentest tools & Open Interpreter…"
  sudo docker exec leviathan bash -lc "\
    apt update && \
    apt install -y python3-pip git nmap sqlmap hydra && \
    pip3 install open-interpreter"

  echo "→ Pulling Dolphin model inside container…"
  sudo docker exec leviathan ollama pull dolphin-mixtral:latest
fi

# —— 7. Web-UI virtualenv ——
echo "→ Setting up Web-UI virtualenv…"
cd "$OW"
if [ ! -d venv ]; then
  python3 -m venv venv
fi
# shellcheck source=/dev/null
source venv/bin/activate
pip install --upgrade pip
if [ -f requirements.txt ]; then
  echo "→ Installing Web-UI Python requirements…"
  pip install -r requirements.txt
else
  echo "→ No requirements.txt found; skipping Python deps."
fi

# —— 8. Interactive menu ——
echo
echo "Select interface:"
echo " 1) Dolphin CLI"
echo " 2) Open-WebUI"
read -p "Enter choice [1-2]: " choice

case "$choice" in
  1)
    echo "→ Launching Dolphin CLI…"
    sudo docker exec -it leviathan ollama run dolphin-mixtral:latest
    ;;
  2)
    echo "→ Starting Open-WebUI…"
    cd "$OW"
    # shellcheck source=/dev/null
    source venv/bin/activate
    python app.py
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac
