#!/usr/bin/env bash

set -euo pipefail

readonly REPO=docker/docker-credential-helpers
readonly NAME=docker-credential-secretservice
readonly BIN=$HOME/.local/bin/$NAME

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" version \
        | awk '{print $3}' \
        | tr -d 'v'
    fi
}

get-latest-version() {
    gh-helper get-latest-release-name "$REPO" \
    | tr -d 'v'
}

get-asset-download-url() {
    local -r version=$1
    printf \
        'https://github.com/docker/docker-credential-helpers/releases/download/v%s/%s-v%s.linux-amd64' \
        "$version" "$NAME" "$version"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cp -f "$asset" "$BIN"
    chmod +x "$BIN"
}
