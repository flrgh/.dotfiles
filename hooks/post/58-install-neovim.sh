#!/usr/bin/env bash

# HOOK .config/nvim/init.vim

set -eu

echo "Updating neovim"
ineed install neovim

echo "Installing tree-sitter CLI"
ineed install tree-sitter

echo "Upgrading tree-sitter grammers"
nvim --headless -c 'TSUpdateSync' -c 'quitall'

echo
echo "Finished"
