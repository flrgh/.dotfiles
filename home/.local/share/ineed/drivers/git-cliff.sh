#!/usr/bin/env bash

set -euo pipefail

readonly REPO=orhun/git-cliff
readonly NAME=git-cliff

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version \
        | sed -r \
            -e 's/git-cliff +//' \
            -e 's/^v//'
    fi
}

get-latest-version() {
    gh-helper get-latest-tag "$REPO" \
    | sed -r -e 's/#v//'
}

get-asset-download-url() {
    local -r version=$1

    echo "https://github.com/$REPO/releases/download/v${version}/git-cliff-${version}-x86_64-unknown-linux-gnu.tar.gz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"

    tar xzf "$asset"
    cd "git-cliff-${version}"
    cp -afv ./git-cliff ~/.local/bin/
}
