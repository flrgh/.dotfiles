#!/usr/bin/env bash

set -euo pipefail

readonly PACKAGES=(
    gopls
    gotags
)

readonly GO_PACKAGES=(
    mvdan.cc/sh/v3/cmd/shfmt@latest
)

# `go install` is trying to run `git tag <tag> <commit>` somewhere, which
# opens a text editor and prompts the user to write a message for the tag,
# completely blocking script execution
export GIT_TERMINAL_PROMPT=0
export GIT_EDITOR=/dev/null

for p in "${PACKAGES[@]}"; do
    ineed install "$p"
done

for p in "${GO_PACKAGES[@]}"; do
    go install "$p"
done
