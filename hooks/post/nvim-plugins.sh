#!/usr/bin/env bash

# HOOK .config/nvim/init.vim

set -eu

echo "Installing python deps for neovim"
pip3 install --user --upgrade pynvim

echo "Updating neovim"
ineed install neovim

echo "Installing neovim plugins"
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

echo "Installing tree-sitter CLI"
"$HOME/.local/libexec/install/tools/install-tree-sitter"

echo "Upgrading tree-sitter grammers"
nvim --headless -c 'TSUpdateSync' -c 'quitall'

echo
echo "Finished"
