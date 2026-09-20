#!/usr/bin/env bash
set -e

# Helper to check if a command exists in PATH
has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

echo "==> Detecting OS and updating system packages..."

OS="$(uname -s)"

if [ "$OS" = "Darwin" ]; then
  echo "--> Detected macOS"
  if has_cmd brew; then
    echo "Updating Homebrew packages..."
    brew update && brew upgrade && brew cleanup
  else
    echo "Warning: Homebrew not found. Skipping macOS system package update."
  fi

elif [ "$OS" = "Linux" ]; then
  if has_cmd apt-get; then
    echo "--> Detected Debian/Ubuntu (or WSL2 Ubuntu)"
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get autoremove -y
  elif has_cmd dnf; then
    echo "--> Detected Fedora / RHEL-family"
    sudo dnf upgrade -y
    sudo dnf autoremove -y
  else
    echo "Warning: Neither apt nor dnf detected. Skipping system package manager."
  fi
else
  echo "Unsupported OS: $OS. Skipping system package manager."
fi

# Dev Environment Updates

echo "==> Updating dev tools..."

# Update mise (if installed)
if has_cmd mise; then
  echo "--> Updating mise and managed runtimes..."
  mise self-update -y || echo "mise self-update skipped (e.g. managed via brew/dnf)"
  mise upgrade
else
  echo "--> mise not found in PATH, skipping."
fi

# Update uv tools (if installed)
if has_cmd uv; then
  echo "--> Upgrading uv global tools..."
  uv tool upgrade --all
else
  echo "--> uv not found in PATH, skipping."
fi

echo "==> All updates complete!"
