#!/usr/bin/env bash

set -euo pipefail

readonly REPO=zigtools/zls
readonly NAME=zls

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version
    fi
}

get-latest-version() {
    gh-helper get-latest-tag "$REPO" \
    | sed -r -e 's/#v//'
}

get-asset-download-url() {
    local -r version=$1

    echo "https://github.com/${REPO}/releases/download/${version}/zls-x86_64-linux.tar.gz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"

    tar xzf "$asset"
    ls -la

    cp -L \
        ./bin/zls \
        "$HOME/.local/bin/$NAME"

    chmod +x "$HOME/.local/bin/$NAME"

    "$NAME" --version
}
