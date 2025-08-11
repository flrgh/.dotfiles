#!/usr/bin/env bash

set -euo pipefail

readonly REPO=bitwarden/clients
readonly BASE_URL=https://github.com/bitwarden/clients/releases/download
readonly NAME=bw

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version
    fi
}

get-latest-version() {
    gh-helper get-releases "$REPO" \
        | jq -r '.[].tag_name | select(test("^cli"))' \
        | sed -re 's/^cli-v//' \
        | sort --version-sort --reverse \
        | head -1
}

get-asset-download-url() {
    local -r version=$1
    # https://github.com/bitwarden/clients/releases/download/cli-v2024.4.1/bw-linux-2024.4.1.zip
    echo "${BASE_URL}/cli-v${version}/bw-linux-${version}.zip"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    local tmp; tmp=$(mktemp -d)
    cd "$tmp"
    unzip "$asset"
    vbin-install "$NAME" "$version" "$PWD/$NAME"
}
