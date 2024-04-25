#!/usr/bin/env bash

set -euo pipefail

readonly REPO=docker/buildx
readonly NAME=docker-buildx
readonly DEST_DIR=${DOCKER_CONFIG:-$HOME/.docker}/cli-plugins
readonly DEST=$DEST_DIR/$NAME

is-installed() {
    test -x "$DEST"
}

get-installed-version() {
    if is-installed; then
        docker buildx version \
        | awk '{print $2}' \
        | sed -r -e 's/-dev//' -e 's/^v//'
    fi
}

get-latest-version() {
    gh-helper get-latest-tag "$REPO"
}

list-available-versions() {
    gh-helper get-release-names "$REPO"
}

get-asset-download-url() {
    local -r version=$1

    echo "https://github.com/$REPO/releases/download/v${version}/buildx-v${version}.linux-amd64"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    mkdir -p "$DEST_DIR"
    cp -av "$asset" "$DEST"
    chmod +x "$DEST"
}
