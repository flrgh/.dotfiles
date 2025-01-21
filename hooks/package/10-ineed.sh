#!/usr/bin/env bash

PACKAGES=(
    bash-completion
    bat
    direnv
    neovim
    tree-sitter
)

for pkg in "${PACKAGES[@]}"; do
    ineed install "$pkg"
done
