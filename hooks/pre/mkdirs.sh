#!/usr/bin/env bash

set -euo pipefail

INSTALL_PATH=${2:-$HOME}

DIRS=(
    .cache
    .cache/download
    .config
    .local
    .local/bin
    .local/include
    .local/lib
    .local/libexec
    .local/share
    .local/var
    .local/var/log
    .local/var/log/nvim
    .local/var/log/lsp
    .local/bash/overrides.d
)

for d in "${DIRS[@]}"; do
    mkdir -v -p "$INSTALL_PATH/$d"
done
