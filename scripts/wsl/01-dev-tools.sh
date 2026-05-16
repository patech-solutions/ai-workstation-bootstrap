#!/usr/bin/env bash
set -euo pipefail

if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# NodeJS LTS via NodeSource - more bootstrap-safe than nvm
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

sudo apt install -y nodejs

node --version
npm --version

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  ssh-keygen -t ed25519 -C "pascal@patech-wsa-01" -f "$HOME/.ssh/id_ed25519" -N ""
fi

echo "Public SSH key:"
cat "$HOME/.ssh/id_ed25519.pub"
