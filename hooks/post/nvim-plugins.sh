#!/usr/bin/env bash

# HOOK .config/nvim/init.vim

set -eu

#echo "Installing python deps for neovim"
#pip3 install --user --upgrade pynvim
#
#echo "Updating neovim"
#ineed install neovim

echo "Installing neovim plugins"
if [[ -e "$HOME/.config/nvim/plugin/packer_compiled.lua" ]]; then
    rm -v "$HOME/.config/nvim/plugin/packer_compiled.lua"
fi
mkdir -pv "$HOME/.local/share/nvim/site/pack/packer/start"
nvim --headless \
    --cmd 'lua _G.___BOOTSTRAP = true' \
    +'autocmd User PackerCompileDone quitall'


echo "Installing tree-sitter CLI"
ineed install tree-sitter

echo "Upgrading tree-sitter grammers"
nvim --headless -c 'TSUpdateSync' -c 'quitall'

echo
echo "Finished"
