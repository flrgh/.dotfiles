#!/usr/bin/env bash

# HOOK .config/nvim/init.vim

set -eu

echo "Installing python deps for neovim"
pip3 install --user --upgrade pynvim

echo "Updating neovim nightly"
"$HOME"/.local/libexec/install/install-neovim-nightly

echo "Installing/updating vim-plug"
readonly REPO=$1
DEST=$("$REPO"/files.d/.local/bin/cache-get \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    "vim-plug.vim"
)
cp -v "$DEST" "$HOME/.config/nvim/autoload/plug.vim"

echo "Installing neovim plugins"
nvim --headless +PlugUpdate +qall

echo "Installing tree-sitter CLI"
"$HOME/.local/libexec/install/tools/install-tree-sitter"

echo "Updating TreeSitter parsers"
nvim --headless +TSUpdate +qall || true

echo
echo "Finished"
