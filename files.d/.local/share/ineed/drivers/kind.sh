#!/usr/bin/env bash

set -euo pipefail

readonly REPO=kubernetes-sigs/kind
readonly INSTALL="$HOME/.local/bin/kind"

is-installed() {
    binary-exists kind
}

get-installed-version() {
    if is-installed; then
        kind --version | awk '{print $3}'
    fi
}

get-latest-version() {
    gh-helper get-latest-release-name "$REPO" | tr -d 'v'
}

list-available-versions() {
    gh-helper get-release-names "$REPO"
}

get-asset-download-url() {
    local -r version=$1
    gh-helper get-tag "$REPO" "$version" \
    | jq -r \
        '.assets[]
        | select(.name == "kind-linux-amd64")
        | .browser_download_url
        '
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cp -v "$asset" "$INSTALL"
    chmod +x "$INSTALL"
}
