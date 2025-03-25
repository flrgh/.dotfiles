#!/usr/bin/env bash

set -euo pipefail

readonly PREFIX=$HOME/.local
readonly NAME=luajit
readonly REPO=openresty/luajit2

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" -v | awk '{print $2}'
    fi
}

list-available-versions() {
    gh-helper get-tag-names "$REPO" \
        | grep -v -- '-beta'
}

get-asset-download-url() {
    local -r version=$1
    echo "https://api.github.com/repos/$REPO/tarball/refs/tags/v${version}"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"

    tar --strip-components 1 \
        --extract \
        --file "$asset"

    local -a env=(
        -j"$(nproc)"
        PREFIX="$HOME/.local"
        VERSION="$version"
    )

    make "${env[@]}"
    make "${env[@]}" install

    local src="$PREFIX/bin/luajit-${version}"

    vbin-install luajit "$version" "$src"

    rm "$src"
}
