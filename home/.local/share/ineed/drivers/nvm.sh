#!/usr/bin/env bash

set -euo pipefail

readonly REPO=nvm-sh/nvm
readonly NAME=nvm

is-installed() {
    function-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version
    fi
}

get-latest-version() {
    gh-helper get-latest-release-name "$REPO"
}

get-asset-download-url() {
    local -r version=$1
    printf 'https://raw.githubusercontent.com/nvm-sh/nvm/v%s/install.sh' \
      "$version"
}

list-available-versions() {
    gh-helper get-release-names "$REPO"
}

install-from-asset() {
    local -r asset=$1
    bash "$asset"
}
