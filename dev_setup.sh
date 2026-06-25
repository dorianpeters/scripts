#!/usr/bin/env bash

# Exit immediately on error
set -e

echo "=================================================="
echo "  JavaScript + Python Dev Environment Setup"
echo "=================================================="

# --------------------------------------------------
# OS detection (Ubuntu, macOS, WSL2)
# --------------------------------------------------
OS=""
IS_WSL=false

case "$(uname -s)" in
  Darwin)
    OS="macos"
    ;;
  Linux)
    OS="linux"
    if grep -qi microsoft /proc/version 2>/dev/null; then
      IS_WSL=true
    fi
    ;;
  *)
    echo "Unsupported operating system"
    exit 1
    ;;
esac

echo "Detected OS: $OS"
[ "$IS_WSL" = true ] && echo "Running inside WSL2"

# --------------------------------------------------
# Install system dependencies
# --------------------------------------------------
echo "--------------------------------------------------"
echo "Installing system packages (git, curl, unzip)"
echo "--------------------------------------------------"

if [ "$OS" = "linux" ]; then
  sudo apt update
  sudo apt install -y git curl unzip
elif [ "$OS" = "macos" ]; then
  # Check if brew exists at common install locations first and add to PATH if so
  if ! command -v brew >/dev/null 2>&1; then
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi

  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this script (Apple Silicon + Intel safe)
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi

  brew update
  brew install git curl unzip
fi  # end: if [ "$OS" = "linux" ] / elif [ "$OS" = "macos" ]

# --------------------------------------------------
# Git configuration
# --------------------------------------------------
echo "--------------------------------------------------"
echo "Configuring Git"
echo "--------------------------------------------------"

git config --global user.name "Dorian Peters"
git config --global user.email "dpeters08@gmail.com"
git config --global init.defaultBranch main
git config --global color.ui auto
git config --global pull.rebase false

# --------------------------------------------------
# SSH key setup
# --------------------------------------------------
echo "--------------------------------------------------"
echo "Checking SSH key"
echo "--------------------------------------------------"

if [ ! -f "$HOME/.ssh/id_ed25519.pub" ]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "dpeters08@gmail.com" -q
  echo "SSH key created. Public key:"
  cat "$HOME/.ssh/id_ed25519.pub"
  echo "Add this key to GitHub / GitLab."
else
  echo "SSH key already exists."
fi

# --------------------------------------------------
# pnpm + Node.js (LTS)
# --------------------------------------------------
echo "--------------------------------------------------"
echo "Installing pnpm and Node.js (LTS)"
echo "--------------------------------------------------"

curl -fsSL https://get.pnpm.io/install.sh | sh -

if [ "$OS" = "macos" ]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
export PATH="$PNPM_HOME:$PNPM_HOME/bin:$PATH"

pnpm runtime set node lts -g

# --------------------------------------------------
# uv + Python (latest)
# --------------------------------------------------
echo "--------------------------------------------------"
echo "Installing uv and latest Python"
echo "--------------------------------------------------"

curl -LsSf https://astral.sh/uv/install.sh | sh

# Ensure uv and Python are available immediately
export PATH="$HOME/.local/bin:$PATH"

# Install latest stable Python
uv python install

# --------------------------------------------------
# Verification
# --------------------------------------------------
echo "--------------------------------------------------"
echo "Verification"
echo "--------------------------------------------------"

echo "Git:    $(git --version)"
echo "pnpm:   $(pnpm --version)"
echo "Node:   $(node --version)"
echo "uv:     $(uv --version)"
echo "Python: $(python3 --version)"

echo "=================================================="
echo "✅ Setup complete!"
echo "=================================================="
