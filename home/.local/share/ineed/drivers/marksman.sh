#!/usr/bin/env bash

# markdown language server

# https://github.com/artempyanykh/marksman


readonly REPO=artempyanykh/marksman
readonly NAME=marksman-linux

_nyi() {
    echo "This function is NYI"
    return 1
}

list-available-versions() {
    gh-helper get-releases "$REPO" \
    | jq -r '.[].name'
}

get-latest-version() {
    gh-helper get-latest-release-name "$REPO"
}


get-installed-version() {
    if is-installed; then
        "$NAME" --version
    fi
}

is-installed() {
    binary-exists "$NAME"
}

get-asset-download-url() {
    local version=$1

    echo "https://github.com/${REPO}/releases/download/${version}/${NAME}-x64"
}

install-from-asset() {
    local asset=$1
    local version=$2

    cp -f "$asset" "$HOME/.local/bin/${NAME}"
    chmod +x "$HOME/.local/bin/${NAME}"
}

get-binary-name() {
    echo marksman-linux
}
