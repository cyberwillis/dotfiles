#!/bin/bash -e
sudo apt install -y zsh

export ZSH="$HOME/.dotfiles/oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended