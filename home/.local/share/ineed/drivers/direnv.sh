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
    local version; version=$(gh-helper get-latest-tag "$REPO")
    echo "${version#v}"
}


get-asset-download-url() {
    local -r version=$1
    echo "https://github.com/${REPO}/releases/download/v${version}/direnv.linux-amd64"
}

post-install() {
    local -r version=$1

    vbin-exec "$NAME" "$version" "$NAME" \
        hook bash \
        > "$HOME/.local/bash/gen.d/direnv"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    vbin-install "$NAME" "$version" "$asset"
    post-install "$version"
}
