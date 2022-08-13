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


get-latest-version() {
    gh-helper get-tags "$REPO" \
    | jq -r '.[].name' \
    | tr -d 'v' \
    | sort -r -n \
    | head -1
}

get-asset-download-url() {
    local -r version=$1
    echo https://api.github.com/repos/openresty/luajit2/tarball/refs/tags/v"$version"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"

    tar xzf "$asset"

    cd openresty-luajit2-*

    sed -i -r \
        -e "s/\"LuaJIT 2.1.0-beta3\"/\"LuaJIT $version\"/g" \
        src/luajit.h

    grep -F "$version" -q src/luajit.h || {
        echo "ERROR: Failed patching src/luajit.sh"
        return 1
    }

    make \
        PREFIX="$PREFIX" \
        VERSION="$version"

    make install \
        PREFIX="$PREFIX" \
        VERSION="$version"

    ln -sfv "$PREFIX/bin/luajit-${version}" "$PREFIX/bin/luajit"
}
