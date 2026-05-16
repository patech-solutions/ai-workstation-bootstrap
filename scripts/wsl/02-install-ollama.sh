#!/usr/bin/env bash
set -euo pipefail

echo "== PaTech WSL bootstrap: Ollama native in WSL =="

if ! command -v zstd >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y zstd
fi

if ! command -v ollama >/dev/null 2>&1; then
  curl -fsSL https://ollama.com/install.sh | sh
fi

if systemctl list-unit-files 2>/dev/null | grep -q '^ollama.service'; then
  sudo systemctl enable ollama || true
  sudo systemctl start ollama || true
fi

if ! curl -fsS http://localhost:11434/api/tags >/dev/null 2>&1; then
  mkdir -p "$HOME/.ollama"
  if ! pgrep -x ollama >/dev/null 2>&1; then
    nohup ollama serve > "$HOME/.ollama/ollama.log" 2>&1 &
    sleep 2
  fi
fi

curl -fsS http://localhost:11434/api/tags >/dev/null
echo "OK: Ollama reachable at http://localhost:11434 inside WSL"
ollama --version
