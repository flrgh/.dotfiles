#!/usr/bin/env bash

set -euo pipefail

# https://github.com/AnalogJ/scrutiny/blob/master/docs/INSTALL_HUB_SPOKE.md
readonly NAME=scrutiny-collector
readonly REPO=AnalogJ/scrutiny
readonly BIN="$HOME/.local/bin/$NAME"

is-installed() {
    test -x "$BIN"
}

get-installed-version() {
    "$BIN" --version | awk '{print $3}'
}

list-available-versions() {
    gh-helper get-tag-names "$REPO"
}

get-asset-download-url() {
    local -r version=$1

    echo "https://github.com/${REPO}/releases/download/v${version}/scrutiny-collector-metrics-linux-amd64"
}


install-from-asset() {
    local -r asset=$1
    local -r version=$2

    vbin-install "$NAME" "$version" "$asset" "${BIN##*/}"

    "$BIN" --version
}
