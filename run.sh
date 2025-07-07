#!/usr/bin/env bash
set -euo pipefail

# Define the local repository directory
LOCAL_REPO_DIR="$HOME/Leviathan"

# Check if the environment is set up
if [ -f "$LOCAL_REPO_DIR/.env_setup" ]; then
  # Run the main script
  bash "$LOCAL_REPO_DIR/main.sh"
else
  echo "Environment not set up. Please run 'main.sh' to set up the environment first."
fi
