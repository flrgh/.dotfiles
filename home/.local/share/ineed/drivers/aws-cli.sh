#!/usr/bin/env bash

set -euo pipefail

readonly NAME=aws-cli
readonly REPO=aws/aws-cli

is-installed() {
    binary-exists aws
}

get-installed-version() {
    if is-installed; then
        aws --version \
            | awk '{print $1}' \
            | awk -F / '{print $2}'
    fi
}

get-latest-version() {
    gh-helper get-latest-tag "$REPO"
}

list-available-versions() {
    gh-helper get-tag-names "$REPO"
}

get-asset-download-url() {
    local version=$1
    echo "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${version}.zip"
}

install-from-asset() {
    local -r asset=$1

    local tmp; tmp=$(mktemp -d)

    unzip -d "$tmp" "$asset" >/dev/null

    cd "$tmp"

    ./aws/install \
        --update \
        --install-dir "$HOME/.local/aws-cli" \
        --bin-dir "$HOME/.local/bin"
}
