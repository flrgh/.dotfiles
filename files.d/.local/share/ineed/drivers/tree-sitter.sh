#!/usr/bin/env bash

set -euo pipefail

readonly REPO=tree-sitter/tree-sitter
readonly NAME=tree-sitter
readonly BIN="$HOME/.local/bin"

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version | awk '{print $2}'
    fi
}

get-latest-version() {
    gh-helper get-latest-release-name "$REPO"
}

get-asset-download-url() {
    local -r version=$1
    echo "https://github.com/tree-sitter/tree-sitter/releases/download/v${version}/tree-sitter-linux-x64.gz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"

    gunzip -d \
        < "$asset" \
        > "$BIN/${NAME}-${version}"

    chmod +x "$BIN/${NAME}-${version}"
    ln -sfv "$BIN/${NAME}-${version}" "$BIN/$NAME"
}
