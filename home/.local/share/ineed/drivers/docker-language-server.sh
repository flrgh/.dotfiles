#!/usr/bin/env bash
# shellcheck disable=SC2034

set -euo pipefail

readonly REPO=docker/docker-language-server
readonly NAME=docker-language-server
readonly BASE_URL=https://github.com/${REPO}/releases/download
readonly BIN=${HOME}/.local/bin/${NAME}

list-available-versions() {
    gh-helper get-tag-names "$REPO"
}

get-installed-version() {
    "$NAME" --version \
        | sed -n -r -e 's/.*v([0-9]+\.[0-9]+\.[0-9]+).*/\1/p'
}

get-binary-name() {
    echo "$NAME"
}

is-installed() {
    command -v "$NAME" &>/dev/null
}

get-asset-download-url() {
    local version=$1
    echo "${BASE_URL}/v${version}/docker-language-server-linux-amd64-v${version}"
}

install-from-asset() {
    local asset=$1
    cp -vfa "$asset" "$BIN"
    chmod +x "$BIN"
}
