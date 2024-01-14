#!/bin/bash

echo "Setting up Git for The Odin Project"
git config --global user.name "Dorian Peters"
git config --global user.email "dpeters08@gmail.com"
git config --global init.defaultBranch main
git config --global color.ui auto
git config --global pull.rebase false

echo "Here is the git name and email address"
git config --get user.name
git config --get user.email
