#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.hermes/profiles"

if [ ! -f "$HOME/.hermes/config.yaml" ]; then
  cp config/hermes-config.template.yaml "$HOME/.hermes/config.yaml"
fi

cat <<'MSG'
Hermes Agent preparation complete.

Next manual step:
- Add the exact Hermes Agent install command/repository for your current setup.
- Validate provider routing and OAuth/provider credentials.
- Keep API keys out of git; use environment variables or a secret store.
MSG
