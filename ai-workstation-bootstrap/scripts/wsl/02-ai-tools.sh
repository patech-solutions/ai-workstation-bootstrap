#!/usr/bin/env bash
set -euo pipefail

if ! command -v ollama >/dev/null 2>&1; then
  echo "Ollama not found in WSL. If using Windows Ollama, this is OK."
else
  ollama --version
fi

docker compose -f compose/open-webui.compose.yml up -d

echo "Open WebUI should be available at http://localhost:3000"
