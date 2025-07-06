# Leviathan AI

Leviathan AI is an all-in-one, AI-powered security workbench. It combines a powerful Mixtral LLM assistant, a browser-based Web UI, and a fully loaded pentest shell—no separate VM. 

## Features

- **Mixtral CLI**  
  - Dolphin-2.5-Mixtral-8x7B base model (no instruction tuning or filters)  
  - Persistent REPL (`mixtral>`) with system prompt on first turn  
- **Open-WebUI**  
  - Graphical interface for the same Mixtral model in your browser  
  - Simple Python virtual environment setup  
- **Pentest Shell**  
  - Neutral `hacker>` prompt pre-loaded with top security tools:  
    `nmap`, `sqlmap`, `hydra`, `nikto`, `john`, `metasploit-framework`, and more  
- **OpenInterpreter Integration**  
  - Clone and install the OpenInterpreter package for AI-driven shell automation  
- **Hacking Tools Collection**  
  - Clones or updates a curated list of public payloads and scripts under `~/tools/hacking-tools`  
  - Automatic branch fallback (main → master)  

## Prerequisites

- Ubuntu 22.04 or later (or any Debian-based distro)  
- `bash`, `curl`, `git`, `python3`  

## Fresh-Start Installation

Run this one-liner from your home directory to wipe any previous setup and get the latest scripts:

```bash
cd ~ \
&& rm -rf Leviathan ~/tools/open-webui ~/tools/open-interpreter ~/tools/hacking-tools ~/.cache/hf_models/dolphin-2.5-mixtral-8x7b \
&& git clone git@github.com:s7612f/Leviathan.git ~/Leviathan \
&& cd ~/Leviathan \
&& chmod +x main.sh \
&& ./main.sh
