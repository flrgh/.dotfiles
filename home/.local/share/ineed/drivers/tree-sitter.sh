#!/usr/bin/env bash

set -euo pipefail

readonly REPO=tree-sitter/tree-sitter
readonly NAME=tree-sitter

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version | awk '{print $2}'
    fi
}

list-available-versions() {
    gh-helper get-tag-names "$REPO"
}

get-latest-version() {
    list-available-versions | sort -Vr | head -1
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
    | vbin-install "$NAME" "$version" -
}
