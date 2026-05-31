#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# Laad bootstrap configuratie
BOOTSTRAP_ENV="$ROOT/config/bootstrap.env"
if [[ ! -f "$BOOTSTRAP_ENV" ]]; then
    echo "ERROR: $BOOTSTRAP_ENV niet gevonden."
    echo "Kopieer config/bootstrap.env.example naar config/bootstrap.env en vul in."
    exit 1
fi
# shellcheck source=../../config/bootstrap.env
source "$BOOTSTRAP_ENV"

echo "AI Workstation WSL bootstrap — ${BOOTSTRAP_HOSTNAME:-ai-workstation}"
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
