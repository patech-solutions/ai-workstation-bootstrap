#!/usr/bin/env bash
set -euo pipefail

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found. Run scripts/wsl/01-dev-tools.sh first."
  exit 1
fi

echo "Installing OpenAI Codex CLI"
npm install -g @openai/codex || echo "Codex install failed; verify current package name or npm auth."

echo "Installing Claude Code CLI"
npm install -g @anthropic-ai/claude-code || echo "Claude install failed; verify current package name, Anthropic access or billing requirements."

cat <<'MSG'
Codex/Claude install step complete.

Next manual steps:
- Run Codex login/OAuth command according to installed CLI help.
- Run Claude login/OAuth command according to installed CLI help.
- Anthropic may require additional billing/usage enablement.
MSG
