#!/usr/bin/env bash

set -euo pipefail

#readonly REPO=LuaJIT/LuaJIT
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
        | tr -d 'v' \
        | sort -r -n
}

get-latest-version() {
    list-available-versions \
        | sort -r -n \
        | head -1
}

get-asset-download-url() {
    local -r version=$1
    echo "https://api.github.com/repos/$REPO/tarball/refs/tags/v${version}"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"

    tar xzf "$asset"

    cd openresty-luajit2-*

    make \
        PREFIX="$PREFIX" \
        VERSION="$version"

    make install \
        PREFIX="$PREFIX" \
        VERSION="$version"

    local bin="$PREFIX/bin/luajit-${version}"

    vbin-install luajit "$version" "$bin"

    rm "$bin"
}
