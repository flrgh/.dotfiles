#!/usr/bin/env bash

set -euo pipefail

readonly REPO=bazelbuild/bazelisk
readonly NAME=bazelisk
readonly ASSET_NAME=bazelisk-linux-amd64

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        local bin; bin=$(type -p "$NAME")
        bin=$(readlink "$bin")

        local version=${bin%/*}
        version=${version##*/}

        echo "$version"
    fi
}

get-latest-version() {
    gh-helper get-latest-release-name "$REPO"
}

get-asset-download-url() {
    local -r version=$1
    echo "https://github.com/bazelbuild/bazelisk/releases/download/v${version}/$ASSET_NAME"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    vbin-install "$NAME" "$version" "$asset"
}
