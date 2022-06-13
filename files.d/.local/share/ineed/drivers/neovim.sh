#!/usr/bin/env bash

set -euo pipefail

readonly REPO=neovim/neovim
readonly NAME=nvim

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version | head -1 | awk '{print $2}'
    fi
}

get-latest-version() {
    gh-helper get-latest-release-tag "$REPO"
}

get-asset-download-url() {
    local -r version=$1

    echo "https://github.com/neovim/neovim/releases/download/${version}/nvim-linux64.tar.gz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    if pidof nvim &>/dev/null; then
        echo "oops, neovim can't be updated while it's already running."
        exit 1
    fi

    cd "$(mktemp -d)"

    tar xzf "$asset"
    cp -af nvim-linux64/bin/* "$HOME/.local/bin/"
    cp -af nvim-linux64/lib/* "$HOME/.local/lib/"
    cp -af nvim-linux64/share/* "$HOME/.local/share/"
}
