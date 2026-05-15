#!/usr/bin/env bash
set -euo pipefail

sudo apt update
sudo apt upgrade -y

sudo apt install -y \
  build-essential \
  curl \
  wget \
  git \
  jq \
  unzip \
  ca-certificates \
  gnupg \
  lsb-release \
  htop \
  btop \
  nvtop \
  tmux \
  direnv \
  ripgrep \
  fd-find \
  fzf \
  tree \
  shellcheck \
  software-properties-common

git config --global user.name "Pascal van de Bor"
git config --global user.email "vandeborp@gmail.com"
git config --global init.defaultBranch main
git config --global core.autocrlf input

echo "Ubuntu bootstrap complete."
