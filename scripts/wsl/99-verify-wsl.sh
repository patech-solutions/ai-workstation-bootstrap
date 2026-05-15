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
uv --version || true

echo "== Ollama =="
ollama list || true

echo "== Hermes config =="
test -f "$HOME/.hermes/config.yaml" && echo "Hermes config present" || echo "Hermes config missing"

echo "== Honcho config =="
test -f "$HOME/.honcho/config.yaml" && echo "Honcho config present" || echo "Honcho config missing"
