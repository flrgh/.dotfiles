#!/usr/bin/env bash

readonly CLEANUP_FILES=(
    ~/.bash_profile
    ~/.bash_logout
)

for f in "${CLEANUP_FILES[@]}"; do
    if [[ -f $f ]]; then
        rm -v "$f" || true
    fi
done
