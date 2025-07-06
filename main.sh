#!/usr/bin/env bash
set -euo pipefail

# 1. System prerequisites
echo "→ Installing system dependencies..."
sudo apt update
sudo apt install -y git curl apt-transport-https ca-certificates gnupg lsb-release \
  python3-pip python3-venv build-essential ffmpeg docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker "$USER"

# 2. Clone/update repos
REPO_DIR="$HOME/Leviathan"
WEBUI_DIR="$HOME/tools/open-webui"

for dir in "$REPO_DIR" "$WEBUI_DIR"; do
  url="$( [ "$dir" == "$REPO_DIR" ] \
    && echo git@github.com:s7612f/Leviathan.git \
    || echo https://github.com/open-webui/open-webui.git )"

  if [ -d "$dir/.git" ]; then
    echo "→ Updating $(basename "$dir")..."
    git -C "$dir" pull origin main
  else
    echo "→ Cloning $(basename "$dir")..."
    git clone "$url" "$dir"
  fi
done

# 3. Ollama CLI & Dolphin model
if ! command -v ollama &>/dev/null; then
  echo "→ Installing Ollama CLI..."
  curl -fsSL https://ollama.com/install.sh | sh
fi

echo "→ Pulling Dolphin model..."
ollama pull dolphin-mixtral:latest

# 4. Build & run Ollama container
if ! docker ps -a --format '{{.Names}}' | grep -qw leviathan; then
  echo "→ Starting Ollama container..."
  docker pull ollama/ollama:latest
  docker run -d --gpus all -p 11434:11434 --name leviathan \
    -v ~/.ollama:/root/.ollama ollama/ollama:latest
  echo "→ Installing tools inside container..."
  docker exec leviathan bash -lc \
    "apt update && apt install -y python3-pip git nmap sqlmap hydra && pip3 install open-interpreter"
  docker exec leviathan ollama pull dolphin3:latest
else
  echo "→ Ollama container already exists, skipping launch."
fi

# 5. Prepare Web-UI venv
WEBUI_DIR="$HOME/tools/open-webui"
cd "$WEBUI_DIR"
if [ ! -d venv ]; then
  echo "→ Creating Web-UI virtualenv..."
  python3 -m venv venv
fi
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 6. Interactive menu
cat << 'EOF'
Select interface:
 1) Dolphin CLI (terminal)
 2) Open-WebUI (browser)
EOF
read -p "Enter choice [1-2]: " choice
case "$choice" in
  1)
    echo "→ Launching Dolphin CLI..."
    docker exec -it leviathan ollama run dolphin3:latest
    ;;
  2)
    echo "→ Starting Web UI..."
    python app.py
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac
