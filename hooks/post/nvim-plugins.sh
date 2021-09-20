#!/usr/bin/env bash

# HOOK .config/nvim/init.vim

set -eu

echo "Installing python deps for neovim"
pip3 install --user --upgrade pynvim

echo "Updating neovim"
"$HOME"/.local/libexec/install/install-neovim latest

echo "Installing neovim plugins"
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerCompile'
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerUpdate'

echo "Installing tree-sitter CLI"
"$HOME/.local/libexec/install/tools/install-tree-sitter"

echo
echo "Finished"
