#!/bin/bash

# Add git repo and install latest version
echo "***Installing git, curl, and nvm***"
sudo add-apt-repository --yes ppa:git-core/ppa
sudo apt update
sudo apt install git curl -y
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Set up git with my name, email, and options suggested by TOP
echo "***Setting up Git for The Odin Project***"
git config --global user.name "Dorian Peters"
git config --global user.email "dpeters08@gmail.com"
git config --global init.defaultBranch main
git config --global color.ui auto
git config --global pull.rebase false

# Setup SSH Key, if needed
if [ ! -f ~/.ssh/id_ed25519.pub ]; then
  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "dpeters08@gmail.com" -q
  echo "***Generated SSH keys. Public key:***"
  cat ~/.ssh/id_ed25519.pub
fi

# Output name and email to make sure it's correct
echo "***Here is the git name, email, and version ***"
git config --get user.name
git config --get user.email
git --version
echo "***Install node by restarting the terminal and running: nvm install --lts  ***"
