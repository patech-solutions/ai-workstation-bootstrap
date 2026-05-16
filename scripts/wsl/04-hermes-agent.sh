#!/usr/bin/env bash
set -euo pipefail

echo "== Install Hermes Agent =="

curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

mkdir -p "$HOME/.hermes/profiles"

cat <<'MSG'
Hermes Agent installed.

Next:
- Start Hermes with: hermes
- Configure provider as OpenAI-compatible/Ollama:
  Base URL: http://localhost:11434/v1
  Model: qwen3:14b
MSG
