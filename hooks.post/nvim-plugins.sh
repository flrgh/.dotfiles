#!/usr/bin/env bash

# HOOK .config/nvim/init.vim

set -eu

echo "Installing neovim plugins"
nvim --headless +PlugUpdate +qall
