#!/bin/bash

# Add git repo and install latest version
echo "*** Installing git, curl, and nvm ***"
sudo add-apt-repository --yes ppa:git-core/ppa
sudo apt update
sudo apt install git curl -y

# Set up git with my name, email, and options suggested by TOP
echo "*** Setting up Git for The Odin Project ***"
git config --global user.name "Dorian Peters"
git config --global user.email "dpeters08@gmail.com"
git config --global init.defaultBranch main
git config --global color.ui auto
git config --global pull.rebase false

# Setup SSH Key, if needed
if [ ! -f ~/.ssh/id_ed25519.pub ]; then
  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "dpeters08@gmail.com" -q
  echo "*** Generated SSH keys. Public key: ***"
  cat ~/.ssh/id_ed25519.pub
fi

# Output name and email to make sure it's correct
echo "*** Here is the git name, email, and version ***"
git config --get user.name
git config --get user.email
git --version

# Install fnm and pnpm
echo "*** Install fnm, node, and pnpm  ***"
curl -o- https://fnm.vercel.app/install | bash
  # Enable corepack/pnpm for all node installs
echo 'export FNM_COREPACK_ENABLED=1' >> ~/.bashrc
  # Add pnpm alias to bashrc
echo 'alias pn=pnpm' >> ~/.bashrc
  # Reload .bashrc after additions
source ~/.bashrc 
fnm install --lts
echo "*** Here is the Node version ***"
node --version
echo "*** Here is the pnpm (pn) version ***"
pn -v
echo "*** Script done ***"
