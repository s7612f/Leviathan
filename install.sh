#!/usr/bin/env bash
set -euo pipefail

# Install Docker
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
   https://download.docker.com/linux/ubuntu \
   \$(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker \$USER

# Pull & start the Ollama container
docker pull ollama/ollama:latest
docker run -d \
  --gpus all \
  -p 11434:11434 \
  --name leviathan \
  -v ~/.ollama:/root/.ollama \
  ollama/ollama:latest

# Install pentest tools & Open Interpreter inside it
docker exec leviathan bash -lc "apt update && \
  apt install -y python3-pip git nmap sqlmap hydra && \
  pip3 install open-interpreter"

# Pull Dolphin
docker exec leviathan ollama pull dolphin3:latest

echo
echo "🎉 Done! To launch it, run:"
echo "  ssh -A ubuntu@150.136.57.205"
echo "  newgrp docker          # if needed"
echo "  cd ~/Leviathan && ./install.sh  # only first-time"
echo "  docker exec -it leviathan ollama run dolphin3:latest"
