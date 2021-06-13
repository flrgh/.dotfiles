#!/usr/bin/env bash

# HOOK .config/nvim/init.vim

set -eu

echo "Installing python deps for neovim"
pip3 install --user --upgrade pynvim

echo "Updating neovim nightly"
"$HOME"/.local/libexec/install/install-neovim-nightly

echo "Installing neovim plugins"
nvim --headless +PackerCompile +qall
nvim --headless +PackerInstall +qall

echo "Installing tree-sitter CLI"
"$HOME/.local/libexec/install/tools/install-tree-sitter"

echo
echo "Finished"
