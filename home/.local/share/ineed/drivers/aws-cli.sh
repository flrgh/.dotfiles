#!/usr/bin/env bash

set -euo pipefail

readonly NAME=aws-cli


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
    echo latest
}

list-available-versions() {
    echo latest
}

get-asset-download-url() {
    echo https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
}

install-from-asset() {
    local -r asset=$1

    local tmp; tmp=$(mktemp -d)

    unzip -d "$tmp" "$asset"

    cd "$tmp"

    ./aws/install \
        --update \
        --install-dir "$HOME/.local/aws-cli" \
        --bin-dir "$HOME/.local/bin"


    echo "Installing ECS CLI"
    curl \
        -s \
        -o "$HOME/.local/bin/ecs-cli" \
        --url https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest
    chmod -v +x "$HOME/.local/bin/ecs-cli"
}
