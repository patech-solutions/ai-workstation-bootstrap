#!/usr/bin/env bash
set -euo pipefail

echo "Installing Claude Code CLI via npm..."

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found. Run scripts/wsl/01-dev-tools.sh first."
  exit 1
fi

npm install -g @anthropic-ai/claude-code

echo ""
echo "Claude CLI installed:"
claude --version || true

cat <<'EOF'

Next:
- Run: claude
- Complete Anthropic login.
- Anthropic may require billing/usage setup before OAuth/API usage works.
- Keep API keys out of Git.

EOF
