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
# Install Minimal System Dependencies (Linux)
# --------------------------------------------------
if [ "$OS" = "linux" ]; then
  echo "--------------------------------------------------"
  echo "Ensuring system packages (curl, git, unzip, build tools)"
  echo "--------------------------------------------------"
  case "$PKG_MANAGER" in
    apt)
      sudo apt update
      sudo apt install -y curl git unzip build-essential
      ;;
    dnf)
      sudo dnf install -y curl git unzip gcc gcc-c++ make
      ;;
    zypper)
      sudo zypper install -y curl git unzip gcc gcc-c++ make
      ;;
    *)
      echo "Notice: Non-standard package manager. Ensure curl, git, unzip, and C build tools are installed."
      ;;
  esac
elif [ "$OS" = "macos" ]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "Git not found. Triggering macOS Command Line Tools installation..."
    xcode-select --install || true
  fi
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
# mise Installation & Shell Configuration
# --------------------------------------------------
echo "--------------------------------------------------"
echo "Checking mise (tool manager)"
echo "--------------------------------------------------"

export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

if ! command -v mise >/dev/null 2>&1; then
  echo "mise not found. Installing mise via https://mise.run..."
  curl -fsSL https://mise.run | sh
fi

if ! command -v mise >/dev/null 2>&1; then
  if [ -x "$HOME/.local/bin/mise" ]; then
    export PATH="$HOME/.local/bin:$PATH"
  else
    echo "Error: mise installation failed or ~/.local/bin/mise is not executable."
    exit 1
  fi
fi

echo "mise version: $(mise --version)"

# Persist mise activation to shell profiles
BASH_ACTIVATE_LINE='eval "$($HOME/.local/bin/mise activate bash)"'
ZSH_ACTIVATE_LINE='eval "$($HOME/.local/bin/mise activate zsh)"'

if [ -f "$HOME/.bashrc" ] || [ -n "$BASH_VERSION" ]; then
  touch "$HOME/.bashrc"
  if ! grep -qF "mise activate bash" "$HOME/.bashrc"; then
    echo "" >> "$HOME/.bashrc"
    echo "# mise tool manager" >> "$HOME/.bashrc"
    echo "$BASH_ACTIVATE_LINE" >> "$HOME/.bashrc"
    echo "Added mise activation to ~/.bashrc"
  fi
fi

if command -v zsh >/dev/null 2>&1 || [ -f "$HOME/.zshrc" ]; then
  touch "$HOME/.zshrc"
  if ! grep -qF "mise activate zsh" "$HOME/.zshrc"; then
    echo "" >> "$HOME/.zshrc"
    echo "# mise tool manager" >> "$HOME/.zshrc"
    echo "$ZSH_ACTIVATE_LINE" >> "$HOME/.zshrc"
    echo "Added mise activation to ~/.zshrc"
  fi
fi

# --------------------------------------------------
# Configure mise Settings
# --------------------------------------------------
echo "--------------------------------------------------"
echo "Configuring mise settings"
echo "--------------------------------------------------"

mise settings set clean true
mise settings set yes true
mise settings set compile false

echo "mise settings configured: clean=true, yes=true, compile=false"

# --------------------------------------------------
# Install Developer Tools via mise
# --------------------------------------------------
echo "--------------------------------------------------"
echo "Installing tools via mise"
echo "--------------------------------------------------"

TOOLS=(
  node@lts
  aube
  uv
  gh
  zoxide
  eza
  fd
  ripgrep
  bat
  sd
  jq
  btop
  tealdeer
  lazygit
  fzf
)

echo "Installing globally: ${TOOLS[*]}"
mise use -g "${TOOLS[@]}"
mise install

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

echo "mise:     $(mise --version 2>/dev/null || echo 'Not installed')"
echo "Node:     $(node --version 2>/dev/null || echo 'Not installed')"
echo "aube:     $(aube --version 2>/dev/null || echo 'Installed')"
echo "uv:       $(uv --version 2>/dev/null || echo 'Not installed')"
echo "Python:   $(uv run python --version 2>/dev/null || echo 'Not installed')"
echo "Git:      $(git --version 2>/dev/null || echo 'Not installed')"
echo "gh:       $(gh --version 2>/dev/null | head -n 1 || echo 'Not installed')"
echo "eza:      $(eza --version 2>/dev/null | head -n 1 || echo 'Installed')"
echo "ripgrep:  $(rg --version 2>/dev/null | head -n 1 || echo 'Installed')"
echo "fd:       $(fd --version 2>/dev/null | head -n 1 || echo 'Installed')"
echo "bat:      $(bat --version 2>/dev/null | head -n 1 || echo 'Installed')"
echo "zoxide:   $(zoxide --version 2>/dev/null || echo 'Installed')"
echo "fzf:      $(fzf --version 2>/dev/null | head -n 1 || echo 'Installed')"
echo "lazygit:  $(lazygit --version 2>/dev/null | head -n 1 || echo 'Installed')"

if git config --global user.name >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1; then
  echo "Git User: $(git config --global user.name) <$(git config --global user.email)>"
fi

echo "=================================================="
echo "✅ Setup complete!"
echo "=================================================="
