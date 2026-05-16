#!/usr/bin/env bash
set -euo pipefail

echo "== Hostname =="
hostname

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
# uv
if command -v uv >/dev/null 2>&1; then
  uv --version
elif [ -x "$HOME/.local/bin/uv" ]; then
  "$HOME/.local/bin/uv" --version
else
  echo "WARN: uv not found"
fi

echo "== Ollama =="
# Ollama
if command -v ollama >/dev/null 2>&1; then
  ollama --version
  ollama list || true
elif curl -fsS http://localhost:11434/api/tags >/dev/null 2>&1; then
  echo "Ollama API reachable via Windows host at localhost:11434"
else
  echo "WARN: ollama not found and API not reachable"
fi

echo "== Hermes config =="
test -f "$HOME/.hermes/config.yaml" && echo "Hermes config present" || echo "Hermes config missing"

echo "== Honcho config =="
test -f "$HOME/.honcho/config.yaml" && echo "Honcho config present" || echo "Honcho config missing"
