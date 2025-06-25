#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "---"
echo "*** Starting JavaScript Development Environment Setup ***"
echo "---"

# Add git repo and install latest version
echo "---"
echo "*** Installing git, curl, and unzip ***"
echo "---"
sudo apt update
sudo apt install git curl unzip -y
if [ $? -ne 0 ]; then
    echo "Error: Failed to install git and curl. Please check your internet connection or repository access."
    exit 1
fi

# Set up git with my name, email, and options
echo "---"
echo "*** Setting up Git ***"
echo "---"

git config --global user.name "Dorian Peters"
git config --global user.email "dpeters08@gmail.com"
git config --global init.defaultBranch main
git config --global color.ui auto
git config --global pull.rebase false

# Setup SSH Key, if needed
echo "---"
echo "*** Checking and generating SSH Key (if needed) ***"
echo "---"
if [ ! -f ~/.ssh/id_ed25519.pub ]; then
    # Ensure .ssh directory exists with correct permissions
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "dpeters08@gmail.com" -q
    echo "*** Generated SSH keys. Your public key is: ***"
    cat ~/.ssh/id_ed25519.pub
    echo "---"
    echo "Please add this public key to your GitHub/GitLab account settings."
    echo "---"
else
    echo "SSH key already exists: ~/.ssh/id_ed25519.pub"
fi

# Output name and email to make sure it's correct
echo "---"
echo "*** Verifying Git Configuration and Version ***"
echo "---"
echo "Git User Name: $(git config --get user.name)"
echo "Git User Email: $(git config --get user.email)"
echo "Git Version: $(git --version)"

# Install fnm and pnpm
echo "---"
echo "*** Installing fnm, Node.js (LTS), and pnpm ***"
echo "---"
curl -o- https://fnm.vercel.app/install | bash
if [ $? -ne 0 ]; then
    echo "Error: Failed to install fnm. Please check your internet connection."
    exit 1
fi

# Make fnm available in this session (installer uses ~/.local/share/fnm)
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
    export PATH="$FNM_PATH:$PATH"
    eval "$(fnm env)"
else
    echo "Error: fnm directory not found at $FNM_PATH. Install may have failed."
    exit 1
fi

# Check if fnm is available, otherwise print error
if ! command -v fnm >/dev/null 2>&1; then
    echo "Error: fnm is not available in PATH after install."
    exit 1
fi

# Install nodejs lts version
fnm install --lts --corepack-enabled

if [ $? -ne 0 ]; then
    echo "Error: Failed to install Node.js LTS with fnm."
    exit 1
fi

# Enable pnpm
corepack enable pnpm
echo 'alias pn=pnpm' >> ~/.bashrc

echo "---"
echo "*** Verification of Node and pnpm installation ***"
echo "---"
echo "Node Version: $(node --version)"
echo "pnpm Version: $(pnpm -v)"

echo "---"
echo "*** Script finished! ***"
