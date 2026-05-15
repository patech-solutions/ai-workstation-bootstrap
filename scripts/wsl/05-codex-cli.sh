#!/usr/bin/env bash
set -euo pipefail

echo "Installing OpenAI Codex CLI via npm..."

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found. Run scripts/wsl/01-dev-tools.sh first."
  exit 1
fi

npm install -g @openai/codex

echo ""
echo "Codex installed:"
codex --version || true

cat <<'EOF'

Next:
- Run: codex login
- Use OAuth when possible.
- Keep API keys out of Git.

EOF
