#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STATE_DIR="$REPO_ROOT/.bootstrap-state-wsl"
mkdir -p "$STATE_DIR"

run_phase() {
  local name="$1"
  local script="$2"
  local marker="$STATE_DIR/${name}.done"

  if [[ -f "$marker" ]]; then
    echo "==> Skipping $name; marker exists"
    return 0
  fi

  if [[ ! -f "$SCRIPT_DIR/$script" ]]; then
    echo "ERROR: script not found: $SCRIPT_DIR/$script" >&2
    exit 1
  fi

  echo "==> Running phase: $name"
  bash "$SCRIPT_DIR/$script"
  touch "$marker"
}

echo "PaTech WSL bootstrap runner"
echo "Repo root: $REPO_ROOT"
echo "State dir : $STATE_DIR"

chmod +x "$SCRIPT_DIR"/*.sh

run_phase "00-bootstrap-ubuntu" "00-bootstrap-ubuntu.sh"
run_phase "01-dev-tools" "01-dev-tools.sh"
run_phase "02-ai-tools" "02-ai-tools.sh"
run_phase "03-hermes-agent" "03-hermes-agent.sh"
run_phase "04-honcho" "04-honcho.sh"
run_phase "05-codex-claude" "05-codex-claude.sh"
run_phase "06-models-ollama" "06-models-ollama.sh"

echo "WSL bootstrap completed. Run scripts/wsl/99-verify-wsl.sh next."
