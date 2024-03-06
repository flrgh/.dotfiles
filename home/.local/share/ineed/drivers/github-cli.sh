#!/usr/bin/env bash

set -euo pipefail

readonly REPO=cli/cli
readonly NAME=gh


is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        gh --version | head -1 | awk '{print $3}'
    fi
}

get-latest-version() {
    gh-helper get-latest-release-tag "$REPO"
}

get-asset-download-url() {
    local -r version=$1
    echo "https://github.com/cli/cli/releases/download/v${version}/gh_${version}_linux_amd64.tar.gz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"

    tar xzf "$asset"
    cp -av "./gh_${version}_linux_amd64/bin" "$HOME/.local/"
    cp -av "./gh_${version}_linux_amd64/share" "$HOME/.local/"
}

get-binary-name() {
    echo gh
}
