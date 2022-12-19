#!/usr/bin/env bash

set -euo pipefail

readonly REPO=neovim/neovim
readonly NAME=nvim

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version \
            | sed -n -r -e 's/^NVIM v?([0-9.]+).*/\1/p'
    fi
}

get-latest-version() {
    gh-helper get-releases "$REPO" \
    | jq -r '.[].tag_name' \
    | grep -vE 'stable|nightly' \
    | sort -r \
    | head -1 \
    | sed -r -e 's/#v//'
}

get-asset-download-url() {
    local -r version=$1

    echo "https://github.com/neovim/neovim/releases/download/v${version}/nvim-linux64.tar.gz"
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
