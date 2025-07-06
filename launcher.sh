#!/usr/bin/env bash
set -euo pipefail

# Main interactive installer and runner for Leviathan

echo "Select action:"
echo " 1) Install all components (Docker, Ollama, Dolphin, Leviathan & Open-WebUI)"
echo " 2) Launch Dolphin CLI"
echo " 3) Launch Open-WebUI"
read -p "Enter choice [1-3]: " action

case "$action" in
  1)
    # —— Install Docker & dependencies ——
    echo "→ Installing Docker and dependencies..."
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release git python3-pip python3-venv build-essential ffmpeg

    # Docker setup
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
       https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker "$USER"

    # Pull & start the Ollama container
    echo "→ Pulling and starting Ollama container..."
    docker pull ollama/ollama:latest
    docker run -d --gpus all -p 11434:11434 --name leviathan -v ~/.ollama:/root/.ollama ollama/ollama:latest

    # Install pentest tools & Open Interpreter
    echo "→ Installing pentest tools in container..."
    docker exec leviathan bash -lc "apt update && apt install -y python3-pip git nmap sqlmap hydra && pip3 install open-interpreter"

    # Pull Dolphin model
    echo "→ Pulling Dolphin model in container..."
    docker exec leviathan ollama pull dolphin3:latest

    echo "✅  Installation complete."
    ;;

  2)
    echo "→ Launching Dolphin CLI..."
    docker exec -it leviathan ollama run dolphin3:latest
    ;;

  3)
    echo "→ Starting Open-WebUI..."
    cd "$HOME/tools/open-webui"
    if [ ! -d "venv" ]; then
      python3 -m venv venv
    fi
    source venv/bin/activate
    python app.py
    ;;

  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac
