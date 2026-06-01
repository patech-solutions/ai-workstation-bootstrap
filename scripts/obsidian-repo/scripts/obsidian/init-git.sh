#!/usr/bin/env bash
set -euo pipefail

: "${OBSIDIAN_VAULT_DIR:?OBSIDIAN_VAULT_DIR is not set}"
: "${OBSIDIAN_GIT_USER_NAME:?OBSIDIAN_GIT_USER_NAME is not set}"
: "${OBSIDIAN_GIT_USER_EMAIL:?OBSIDIAN_GIT_USER_EMAIL is not set}"

cd "${OBSIDIAN_VAULT_DIR}"

if [ ! -d ".git" ]; then
  git init
fi

git config user.name "${OBSIDIAN_GIT_USER_NAME}"
git config user.email "${OBSIDIAN_GIT_USER_EMAIL}"

cat > .gitignore <<'EOF'
# OS files
.DS_Store
Thumbs.db

# Obsidian UI state
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.obsidian/cache

# Sensitive directories
.secrets/
.private/

# Temp files
*.tmp
*.bak

# Local-only AI work (niet gesynchroniseerd)
00-inbox/
06-ai-memory/
07-publish/staging/
EOF

git add .

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  git commit -m "Initial AI workspace"
else
  git commit -m "Update workspace structure" || true
fi

# Remote instellen vanuit env of standaard Gitea-locatie
GITEA_REMOTE="${OBSIDIAN_GIT_REMOTE:-}"
if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "$GITEA_REMOTE"
  echo "Remote ingesteld: $GITEA_REMOTE"
  echo "Opmerking: push vereist Gitea-token in ~/.git-credentials (credential.helper=store)"
fi

echo "Git initialized."