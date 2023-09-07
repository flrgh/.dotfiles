#!/usr/bin/env bash

set -euo pipefail

readonly NAME=ecs-cli
readonly REPO=aws/amazon-ecs-cli

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version | awk '{print $3}'
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
    echo "https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-v${version}"
}

install-from-asset() {
    local -r asset=$1
    echo "Installing ECS CLI"
    cp -v "$asset" "$HOME/.local/bin/$NAME"
    chmod +x "$HOME/.local/bin/$NAME"
}
