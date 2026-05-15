#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.honcho/data"

if [ ! -f "$HOME/.honcho/config.yaml" ]; then
  cp config/honcho-config.template.yaml "$HOME/.honcho/config.yaml"
fi

cat <<'MSG'
Honcho preparation complete.

Next manual step:
- Add the exact Honcho install/run method used in your environment.
- Recommended: keep Honcho local-only unless deliberately exposed.
MSG
