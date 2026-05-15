#!/usr/bin/env bash
set -euo pipefail

MODEL_FILE="${1:-config/ollama-models.txt}"

if [ ! -f "$MODEL_FILE" ]; then
  echo "Model file not found: $MODEL_FILE"
  exit 1
fi

while read -r model; do
  [[ -z "$model" || "$model" =~ ^# ]] && continue
  echo "Pulling $model"
  ollama pull "$model"
done < "$MODEL_FILE"

ollama list
