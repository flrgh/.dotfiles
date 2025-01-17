#!/usr/bin/env bash

readonly INSTALL_PATH=${INSTALL_PATH:?INSTALL_PATH undefined}

readonly CLEANUP_FILES=(
    "$INSTALL_PATH"/.bash_profile
    "$INSTALL_PATH"/.bash_logout
)

for f in "${CLEANUP_FILES[@]}"; do
    if [[ -f $f ]]; then
        rm -v "$f" || true
    fi
done
