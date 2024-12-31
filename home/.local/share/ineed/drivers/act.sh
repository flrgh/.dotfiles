#!/usr/bin/env bash

set -euo pipefail

readonly REPO=nektos/act
readonly NAME=act

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version | awk '{print $3}'
    fi
}

get-latest-version() {
    gh-helper get-latest-release-name "$REPO"
}

get-asset-download-url() {
    local -r version=$1
    echo "https://github.com/nektos/act/releases/download/v${version}/act_Linux_x86_64.tar.gz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"
    tar xzf "$asset"
    vbin-install act "$version" "$PWD/act"
}
