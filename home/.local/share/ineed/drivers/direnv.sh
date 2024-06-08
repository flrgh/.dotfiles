#!/usr/bin/env bash

set -euo pipefail

readonly NAME=direnv
readonly REPO=direnv/direnv

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version
    fi
}

get-latest-version() {
    local version; version=$(gh-helper get-latest-release-name "$REPO")
    echo "${version#v}"
}


get-asset-download-url() {
    local -r version=$1
    echo "https://github.com/${REPO}/releases/download/v${version}/direnv.linux-amd64"
}

install-from-asset() {
    local -r asset=$1

    cp "$asset" "$HOME/.local/bin/direnv"

    chmod +x "$HOME/.local/bin/direnv"
}
