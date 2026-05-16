#!/usr/bin/env bash
set -euo pipefail

MODEL_FILE="${1:-config/ollama-models.txt}"

if ! command -v ollama >/dev/null 2>&1; then
  echo "Ollama CLI not found in WSL. Use Windows Ollama or install Ollama in WSL first."
  exit 0
fi

while read -r model; do
  [[ -z "$model" || "$model" =~ ^# ]] && continue
  echo "Pulling $model"
  ollama pull "$model" || echo "Failed to pull $model; check model name."
done < "$MODEL_FILE"

ollama list
