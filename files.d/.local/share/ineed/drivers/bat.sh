#!/usr/bin/env bash

set -euo pipefail

readonly NAME=bat
readonly REPO=sharkdp/bat

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version \
            | awk '{print $2}'
    fi
}

get-latest-version() {
    local version; version=$(gh-helper get-latest-release-name "$REPO")
    echo "${version#v}"
}


get-asset-download-url() {
    local -r version=$1
    echo "https://github.com/sharkdp/bat/releases/download/v${version}/bat-v${version}-x86_64-unknown-linux-gnu.tar.gz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"

    tar xzf "$asset"

    cp -a -v ./bat*/bat "$HOME/.local/bin/"
}
