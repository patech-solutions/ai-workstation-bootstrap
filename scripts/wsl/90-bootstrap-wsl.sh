#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "PaTech WSL bootstrap for patech-wsa-01"
echo "Repository root: $ROOT"

chmod +x scripts/wsl/*.sh

./scripts/wsl/00-bootstrap-ubuntu.sh
./scripts/wsl/01-dev-tools.sh
./scripts/wsl/02-install-ollama.sh
./scripts/wsl/03-models-ollama.sh
./scripts/wsl/04-hermes-agent.sh
./scripts/wsl/05-honcho.sh
./scripts/wsl/06-open-webui.sh

echo "WSL bootstrap complete."