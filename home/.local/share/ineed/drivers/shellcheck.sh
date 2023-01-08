#!/usr/bin/env bash

set -euo pipefail

readonly REPO=koalaman/shellcheck
readonly NAME=shellcheck

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version \
        | sed -n -r -e 's/^version: (.+)/\1/p'
    fi
}

get-latest-version() {
    gh-helper get-latest-release-tag "$REPO" \
    | tr -d v
}

get-asset-download-url() {
    local -r version=$1

    printf \
        'https://github.com/%s/releases/download/v%s/shellcheck-v%s.linux.x86_64.tar.xz' \
        "$REPO" \
        "$version" \
        "$version"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"
    tar xf "$asset"
    mv "$NAME-v$version/$NAME" \
        "$HOME/.local/bin/$NAME"

    chmod +x "$HOME/.local/bin/$NAME"
}
