#!/usr/bin/env bash
set -euo pipefail

# Interactive launcher for Leviathan

echo "Select interface:"
echo " 1) Dolphin CLI (terminal)"
echo " 2) Open-WebUI (browser)"
read -p "Enter choice [1-2]: " choice

case "$choice" in
  1)
    echo "→ Launching Dolphin CLI..."
    docker exec -it leviathan ollama run dolphin3:latest
    ;;
  2)
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
