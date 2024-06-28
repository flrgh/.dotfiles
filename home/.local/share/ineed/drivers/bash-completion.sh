#!/usr/bin/env bash
# shellcheck disable=SC2034

readonly REPO=scop/bash-completion
readonly NAME=bash-completion

list-available-versions() {
    gh-helper get-release-names "$REPO" \
        | grep -vE '^(null|)$'
}

get-latest-version() {
    gh-helper get-latest-release-name "$REPO"
}

get-installed-version() {
    echo "2.11"
}

get-binary-name() {
    echo "$NAME"
}

is-installed() {
    return 0
}

get-asset-download-url() {
    local version=$1
    echo "https://github.com/${REPO}/releases/download/${version}/bash-completion-${version}.tar.xz"
}

install-from-asset() {
    local asset=$1
    local version=$2

    local tmp; tmp=$(mktemp -d)
    cd "$tmp" || return 1

    tar xf "$asset"
    cd "bash-completion-${version}" || return 1

    ./configure --prefix="$HOME/.local"
    make install
}
