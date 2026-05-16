#!/usr/bin/env bash
set -euo pipefail

echo "== PaTech WSL bootstrap: base Ubuntu packages =="

sudo apt update
sudo apt upgrade -y

sudo apt install -y \
  build-essential \
  ca-certificates \
  curl \
  wget \
  git \
  jq \
  unzip \
  zip \
  tar \
  zstd \
  gnupg \
  lsb-release \
  software-properties-common \
  apt-transport-https \
  htop \
  btop \
  tmux \
  direnv \
  ripgrep \
  fd-find \
  fzf \
  tree \
  shellcheck \
  netcat-openbsd

git config --global core.autocrlf false
git config --global core.eol lf

echo "== Base Ubuntu bootstrap complete =="
