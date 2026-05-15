#!/usr/bin/env bash
set -euo pipefail

echo "== OS =="
lsb_release -a || cat /etc/os-release

echo "== GPU =="
nvidia-smi || echo "No NVIDIA visible in WSL"

echo "== Docker =="
docker version || true
docker compose version || true

echo "== Dev tools =="
git --version
python3 --version
node --version || true
npm --version || true
uv --version || true

echo "== Ollama =="
curl -s http://localhost:11434/api/tags | jq . || echo "Ollama not reachable"

echo "== Open WebUI =="
curl -I http://localhost:3000 || true

echo "== Honcho =="
curl -I http://localhost:8000 || true

echo "== Codex =="
codex --version || true

echo "== Claude =="
claude --version || true

echo "== Hermes =="
hermes --version || true
