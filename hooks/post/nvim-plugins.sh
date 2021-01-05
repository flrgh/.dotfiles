#!/usr/bin/env bash

# HOOK .config/nvim/init.vim

set -eu

echo "Installing python deps for neovim"
pip3 install --user --upgrade pynvim

echo "Installing/updating vim-plug"
curl -f \
    -s \
    -L \
    -o "$HOME/.config/nvim/autoload/plug.vim" \
    --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo "Installing neovim plugins"
nvim --headless +PlugUpdate +qall
