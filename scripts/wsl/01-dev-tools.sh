#!/usr/bin/env bash
set -euo pipefail

if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# Node via nvm
export NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# nvm.sh is not fully nounset-safe, so temporarily disable -u
set +u
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
set -u

nvm install --lts
nvm use --lts
nvm alias default 'lts/*'

node --version
npm --version

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  ssh-keygen -t ed25519 -C "pascal@patech-wsa-01" -f "$HOME/.ssh/id_ed25519" -N ""
fi

echo "Public SSH key:"
cat "$HOME/.ssh/id_ed25519.pub"
