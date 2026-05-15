#!/usr/bin/env bash
set -euo pipefail

echo "Hermes Agent installer placeholder."
echo ""
echo "This script prepares directories and config locations without assuming your exact Hermes install source."

mkdir -p "$HOME/.hermes"
mkdir -p "$HOME/.config/hermes"

if [ -f "config/hermes-config.example.yaml" ] && [ ! -f "$HOME/.config/hermes/config.yaml" ]; then
  cp config/hermes-config.example.yaml "$HOME/.config/hermes/config.yaml"
  echo "Copied example config to ~/.config/hermes/config.yaml"
fi

cat <<'EOF'

Next steps:
1. Install Hermes Agent using your current preferred source/method.
2. Place the executable in PATH, for example ~/.local/bin/hermes.
3. Review ~/.config/hermes/config.yaml.
4. Add OpenRouter/OpenAI/Anthropic tokens via secure env/secrets, not in Git.

EOF

if command -v hermes >/dev/null 2>&1; then
  hermes --version || true
else
  echo "Hermes executable not found yet."
fi
