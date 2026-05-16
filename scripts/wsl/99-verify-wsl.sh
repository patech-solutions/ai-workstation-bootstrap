#!/usr/bin/env bash
set -euo pipefail

echo "== WSL verification =="

echo
echo "== OS =="
lsb_release -a || cat /etc/os-release

echo
echo "== Hostname =="
hostname

echo
echo "== Git =="
git --version

echo
echo "== Python =="
python3 --version

echo
echo "== uv =="
if command -v uv >/dev/null 2>&1; then
  uv --version
elif [ -x "$HOME/.local/bin/uv" ]; then
  "$HOME/.local/bin/uv" --version
else
  echo "WARN: uv not found"
fi

echo
echo "== Node/npm =="
node --version || echo "WARN: node not found"
npm --version || echo "WARN: npm not found"

echo
echo "== Docker =="
docker version || echo "WARN: docker not available from WSL"
docker compose version || echo "WARN: docker compose not available from WSL"

echo
echo "== NVIDIA =="
nvidia-smi || echo "WARN: NVIDIA not visible from WSL"

echo
echo "== zstd =="
zstd --version || echo "WARN: zstd not found"

echo
echo "== Ollama WSL-native =="
if command -v ollama >/dev/null 2>&1; then
  ollama --version
else
  echo "ERROR: ollama command not found in WSL"
  exit 1
fi

if curl -fsS http://localhost:11434/api/tags >/dev/null 2>&1; then
  echo "OK: Ollama API reachable at http://localhost:11434"
  ollama list
else
  echo "ERROR: Ollama API not reachable at http://localhost:11434"
  echo "Try: ollama serve"
  exit 1
fi

echo
echo "Verification complete."
