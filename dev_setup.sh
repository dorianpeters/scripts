#!/usr/bin/env bash

# Exit immediately on error
set -e

echo "=================================================="
echo "  Cross-Platform Development Environment Setup"
echo "=================================================="

# --------------------------------------------------
# OS & Distro Detection (Fedora, Ubuntu, Debian/Crostini, WSL2, macOS)
# --------------------------------------------------
OS=""
IS_WSL=false

case "$(uname -s)" in
  Darwin)
    OS="macos"
    ;;
  Linux)
    OS="linux"
    if grep -qi microsoft /proc/version 2>/dev/null || uname -r | grep -qi microsoft || [ -n "$WSL_DISTRO_NAME" ]; then
      IS_WSL=true
    fi
    ;;
  *)
    echo "Unsupported operating system: $(uname -s)"
    exit 1
    ;;
esac

echo "Detected OS: $OS"
[ "$IS_WSL" = true ] && echo "Environment: WSL2"

PKG_MANAGER=""
if [ "$OS" = "linux" ] && [ -f /etc/os-release ]; then
  # Source os-release to determine distro family
  . /etc/os-release
  case "$ID" in
    ubuntu|debian|pop|linuxmint|elementary|zorin|kali)
      PKG_MANAGER="apt"
      ;;
    fedora|rhel|centos|rocky|almalinux|amzn)
      PKG_MANAGER="dnf"
      ;;
    opensuse*|suse*)
      PKG_MANAGER="zypper"
      ;;
    *)
      case "$ID_LIKE" in
        *debian*) PKG_MANAGER="apt"    ;;
        *fedora*) PKG_MANAGER="dnf"    ;;
        *suse*)   PKG_MANAGER="zypper" ;;
      esac
      ;;
  esac
  echo "Linux Distribution: ${NAME:-$ID} (Package manager: ${PKG_MANAGER:-unknown})"
fi

# --------------------------------------------------
# Personal Information Resolution (Git Name & Email)
# --------------------------------------------------
# Priority order:
# 1. Pre-existing environment variables (GIT_NAME / GIT_EMAIL or GIT_AUTHOR_*)
# 2. Local or home .dev_setup.env configuration file
# 3. Existing global git configuration
# 4. Interactive prompt (if running in a terminal)

GIT_NAME="${GIT_NAME:-$GIT_AUTHOR_NAME}"
GIT_EMAIL="${GIT_EMAIL:-$GIT_AUTHOR_EMAIL}"

if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
  if [ -f "$PWD/.dev_setup.env" ]; then
    echo "Loading configuration from $PWD/.dev_setup.env"
    # shellcheck disable=SC1091
    . "$PWD/.dev_setup.env"
  elif [ -f "$HOME/.dev_setup.env" ]; then
    echo "Loading configuration from $HOME/.dev_setup.env"
    # shellcheck disable=SC1091
    . "$HOME/.dev_setup.env"
  fi
  GIT_NAME="${GIT_NAME:-$GIT_AUTHOR_NAME}"
  GIT_EMAIL="${GIT_EMAIL:-$GIT_AUTHOR_EMAIL}"
fi

if [ -z "$GIT_NAME" ] && command -v git >/dev/null 2>&1; then
  GIT_NAME="$(git config --global user.name 2>/dev/null || true)"
fi

if [ -z "$GIT_EMAIL" ] && command -v git >/dev/null 2>&1; then
  GIT_EMAIL="$(git config --global user.email 2>/dev/null || true)"
fi

if [ -t 0 ]; then
  if [ -z "$GIT_NAME" ]; then
    read -rp "Enter your Git user name: " GIT_NAME
  fi
  if [ -z "$GIT_EMAIL" ]; then
    read -rp "Enter your Git user email: " GIT_EMAIL
  fi

  if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ] && [ ! -f "$HOME/.dev_setup.env" ] && [ ! -f "$PWD/.dev_setup.env" ]; then
    read -rp "Save these details to ~/.dev_setup.env for future runs? [y/N]: " SAVE_ENV
    case "$SAVE_ENV" in
      [yY][eE][sS]|[yY])
        cat <<EOF > "$HOME/.dev_setup.env"
GIT_NAME="$GIT_NAME"
GIT_EMAIL="$GIT_EMAIL"
EOF
        chmod 600 "$HOME/.dev_setup.env"
        echo "Saved configuration to $HOME/.dev_setup.env"
        ;;
    esac
  fi
fi

# --------------------------------------------------
# Homebrew Detection & Installation
# --------------------------------------------------
echo "--------------------------------------------------"
echo "Checking Homebrew"
echo "--------------------------------------------------"

load_homebrew() {
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  elif command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
  fi
}

load_homebrew

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing Homebrew..."

  if [ "$OS" = "linux" ]; then
    echo "Installing system prerequisites for Homebrew..."
    case "$PKG_MANAGER" in
      apt)
        sudo apt update
        sudo apt install -y build-essential procps curl file git
        ;;
      dnf)
        sudo dnf install -y gcc gcc-c++ make procps-ng curl file git
        ;;
      zypper)
        sudo zypper install -y gcc gcc-c++ make procps curl file git
        ;;
      *)
        echo "Unsupported Linux distribution package manager."
        echo "Please install build tools, procps, curl, file, and git, then re-run."
        exit 1
        ;;
    esac
  fi

  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_homebrew
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew installation failed or brew is not in PATH."
  exit 1
fi

echo "Homebrew version: $(brew --version | head -n 1)"

# Persist Homebrew to shell profiles
BREW_PREFIX="$(brew --prefix)"
BREW_SHELLENV_LINE="eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\""

if [ -f "$HOME/.bashrc" ] || [ -n "$BASH_VERSION" ]; then
  touch "$HOME/.bashrc"
  if ! grep -qF "brew shellenv" "$HOME/.bashrc"; then
    echo "" >> "$HOME/.bashrc"
    echo "# Homebrew environment" >> "$HOME/.bashrc"
    echo "$BREW_SHELLENV_LINE" >> "$HOME/.bashrc"
    echo "Added Homebrew to ~/.bashrc"
  fi
fi

if command -v zsh >/dev/null 2>&1 || [ -f "$HOME/.zshrc" ]; then
  touch "$HOME/.zshrc"
  if ! grep -qF "brew shellenv" "$HOME/.zshrc"; then
    echo "" >> "$HOME/.zshrc"
    echo "# Homebrew environment" >> "$HOME/.zshrc"
    echo "$BREW_SHELLENV_LINE" >> "$HOME/.zshrc"
    echo "Added Homebrew to ~/.zshrc"
  fi
fi

# Ensure ~/.local/bin is in PATH for user scripts and uv tools
export PATH="$HOME/.local/bin:$PATH"

# --------------------------------------------------
# Install Tools via Homebrew (git, gh, uv, bun)
# --------------------------------------------------
echo "--------------------------------------------------"
echo "Installing tools via Homebrew (git, gh, uv, bun)"
echo "--------------------------------------------------"

brew install git gh uv bun

# --------------------------------------------------
# Git Configuration
# --------------------------------------------------
echo "--------------------------------------------------"
echo "Configuring Git"
echo "--------------------------------------------------"

if [ -n "$GIT_NAME" ]; then
  git config --global user.name "$GIT_NAME"
  echo "Configured git user.name: $GIT_NAME"
else
  echo "Notice: Git user.name not provided. Keeping current: $(git config --global user.name 2>/dev/null || echo 'unset')"
fi

if [ -n "$GIT_EMAIL" ]; then
  git config --global user.email "$GIT_EMAIL"
  echo "Configured git user.email: $GIT_EMAIL"
else
  echo "Notice: Git user.email not provided. Keeping current: $(git config --global user.email 2>/dev/null || echo 'unset')"
fi

git config --global init.defaultBranch main
git config --global color.ui auto
git config --global pull.rebase false

# --------------------------------------------------
# GitHub CLI (gh) & SSH Key Setup
# --------------------------------------------------
echo "--------------------------------------------------"
echo "GitHub CLI & SSH Key Setup"
echo "--------------------------------------------------"

if gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is authenticated."
elif [ -t 0 ]; then
  echo "GitHub CLI is not authenticated."
  read -rp "Would you like to run 'gh auth login' now to authenticate and set up SSH keys? [y/N]: " RUN_GH_AUTH
  case "$RUN_GH_AUTH" in
    [yY][eE][sS]|[yY])
      gh auth login
      ;;
    *)
      echo "Skipping 'gh auth login'."
      echo "Tip: Run 'gh auth login' anytime to authenticate and generate/upload SSH keys to GitHub."
      ;;
  esac
else
  echo "Tip: Run 'gh auth login' in an interactive terminal to authenticate and configure SSH keys with GitHub."
fi

# --------------------------------------------------
# uv + Python (latest stable)
# --------------------------------------------------
echo "--------------------------------------------------"
echo "Installing Python via uv"
echo "--------------------------------------------------"

uv python install

# --------------------------------------------------
# Verification
# --------------------------------------------------
echo "--------------------------------------------------"
echo "Verification"
echo "--------------------------------------------------"

echo "Homebrew: $(brew --version | head -n 1)"
echo "Git:      $(git --version)"
echo "gh:       $(gh --version | head -n 1)"
echo "Bun:      $(bun --version 2>/dev/null || echo 'Not installed')"
echo "uv:       $(uv --version)"
echo "Python:   $(uv run python --version 2>/dev/null || echo 'Not installed')"

if git config --global user.name >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1; then
  echo "Git User: $(git config --global user.name) <$(git config --global user.email)>"
fi

echo "=================================================="
echo "✅ Setup complete!"
echo "=================================================="
