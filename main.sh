#!/usr/bin/env bash
set -euo pipefail

# 1. System prerequisites
echo "→ Installing system dependencies..."
sudo apt update
sudo apt install -y git curl python3-pip python3-venv build-essential ffmpeg \
  apt-transport-https ca-certificates gnupg lsb-release

# 2. Docker setup
if ! command -v docker &>/dev/null; then
  echo "→ Installing Docker..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io
  sudo usermod -aG docker "$USER"
fi

# 3. Clone/update repos
REPO_DIR="$HOME/Leviathan"
WEBUI_DIR="$HOME/tools/open-webui"
for dir in "$REPO_DIR" "$WEBUI_DIR"; do
  url="$( [ "$dir" == "$REPO_DIR" ] && echo git@github.com:s7612f/Leviathan.git || echo https://github.com/open-webui/open-webui.git )"
  if [ -d "$dir/.git" ]; then
    echo "→ Updating $(basename "$dir")..."
    git -C "$dir" pull origin main
  else
    echo "→ Cloning $(basename "$dir")..."
    git clone "$url" "$dir"
  fi
done

# 4. Ollama CLI & Dolphin model
if ! command -v ollama &>/dev/null; then
  echo "→ Installing Ollama CLI..."
  curl -fsSL https://ollama.com/install.sh | sh
fi
echo "→ Pulling Dolphin model..."
ollama pull dolphin-mixtral:latest

# 5. Start Ollama container with pentest tools
if ! docker ps -a --format '{{.Names}}' | grep -qw leviathan; then
  echo "→ Starting Ollama Docker container..."
  docker pull ollama/ollama:latest
  docker run -d --gpus all -p 11434:11434 --name leviathan \
    -v ~/.ollama:/root/.ollama ollama/ollama:latest
  echo "→ Installing tools inside container..."
  docker exec leviathan bash -lc "apt update && apt install -y python3-pip git nmap sqlmap hydra && pip3 install open-interpreter"
  docker exec leviathan ollama pull dolphin3:latest
else
  echo "→ Ollama container already exists."
fi

# 6. Prepare Web-UI virtual environment
cd "$WEBUI_DIR"
if [ ! -d venv ]; then
  echo "→ Creating Web-UI virtualenv..."
  python3 -m venv venv
fi
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 7. Interactive menu
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
```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. System prerequisites
echo "→ Installing system dependencies..."
sudo apt update
sudo apt install -y git curl python3-pip python3-venv build-essential ffmpeg

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

# 3. Install Ollama CLI & Dolphin model locally
if ! command -v ollama &>/dev/null; then
  echo "→ Installing Ollama CLI..."
  curl -fsSL https://ollama.com/install.sh | sh
fi

echo "→ Pulling Dolphin model..."
ollama pull dolphin-mixtral:latest

# 4. Prepare Web-UI virtual environment
cd "$WEBUI_DIR"
if [ ! -d venv ]; then
  echo "→ Creating Web-UI virtualenv..."
  python3 -m venv venv
fi
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 5. Interactive menu
cat << 'EOF'
Select interface:
 1) Dolphin CLI (terminal)
 2) Open-WebUI (browser)
EOF
read -p "Enter choice [1-2]: " choice

case "$choice" in
  1)
    echo "→ Launching Dolphin CLI..."
    ollama shell dolphin-mixtral:latest
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
