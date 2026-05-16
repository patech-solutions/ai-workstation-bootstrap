#!/usr/bin/env bash
set -euo pipefail

MODEL_FILE="${1:-config/ollama-models.txt}"

if ! command -v ollama >/dev/null 2>&1; then
  echo "ERROR: ollama command not found. Run scripts/wsl/02-install-ollama.sh first."
  exit 1
fi

if ! curl -fsS http://localhost:11434/api/tags >/dev/null 2>&1; then
  echo "ERROR: Ollama API not reachable at http://localhost:11434"
  echo "Try: ollama serve"
  exit 1
fi

if [ ! -f "$MODEL_FILE" ]; then
  echo "ERROR: model file not found: $MODEL_FILE"
  exit 1
fi

while read -r model; do
  [[ -z "$model" || "$model" =~ ^# ]] && continue
  echo "Pulling $model"
  ollama pull "$model"
done < "$MODEL_FILE"

ollama list
