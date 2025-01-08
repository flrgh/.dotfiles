#!/usr/bin/env bash

set -euo pipefail

readonly REPO=docker/scout-cli
readonly NAME=docker-scout
readonly DEST_DIR=${DOCKER_CONFIG:-$HOME/.docker}/cli-plugins
readonly DEST=$DEST_DIR/$NAME

is-installed() {
    test -x "$DEST"
}

get-installed-version() {
    if is-installed; then
        docker scout version \
        | awk '{print $2}' \
        | sed -r -e 's/-dev//' -e 's/^v//'
    fi
}

get-latest-version() {
    gh-helper get-latest-stable-release "$REPO" \
        | jq -r '.tag_name'
}

list-available-versions() {
    gh-helper get-stable-releases "$REPO" \
        | jq -r '.[].tag_name'
}

get-asset-download-url() {
    local -r version=$1

    echo "https://github.com/${REPO}/releases/download/v${version}/docker-scout_${version}_linux_amd64.tar.gz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    mkdir -p "$DEST_DIR"

    local tmp; tmp=$(mktemp -d)
    cd "$tmp"

    tar xzf "$asset"
    chmod +x "$NAME"
    cp -av "$NAME" "$DEST_DIR/"
}
