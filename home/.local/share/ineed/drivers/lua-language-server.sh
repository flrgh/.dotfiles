#!/usr/bin/env bash

set -euo pipefail

readonly NAME=lua-language-server
readonly REPO=sumneko/lua-language-server

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version \
        | sed -r -e 's/-dev//'
    fi
}

get-latest-version() {
    gh-helper get-latest-tag "$REPO"
}

list-available-versions() {
    gh-helper get-release-names "$REPO"
}

get-asset-download-url() {
    local -r version=$1

    echo "https://github.com/${REPO}/releases/download/${version}/lua-language-server-${version}-linux-x64.tar.gz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    local t; t=$(mktemp -d)

    tar -C "$t" -xzf "$asset"

    rsync -HavP \
        --remove-source-files \
        --delete \
        "$t/" \
        "$HOME/.local/libexec/lua-language-server/"

    rm -rf "$t"
}
