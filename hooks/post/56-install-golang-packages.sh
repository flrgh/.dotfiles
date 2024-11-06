#!/usr/bin/env bash

set -euo pipefail

readonly PACKAGES=(
    golang.org/x/tools/gopls@latest
    github.com/jstemmer/gotags@latest
)

for p in "${PACKAGES[@]}"; do
    go install "$p"
done
