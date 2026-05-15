#!/usr/bin/env bash
set -euo pipefail

echo "Checking Ollama..."
if command -v ollama >/dev/null 2>&1; then
  ollama --version
else
  echo "Ollama CLI not found in WSL. If installed on Windows, use http://localhost:11434 from WSL."
fi

echo "Starting Open WebUI via Docker Compose..."
docker compose -f compose/open-webui.compose.yml up -d

echo "AI runtime layer complete."
