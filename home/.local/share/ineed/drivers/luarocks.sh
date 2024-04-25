#!/usr/bin/env bash

set -euo pipefail

readonly NAME=luarocks
readonly PREFIX=$HOME/.local

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        luarocks --version | head -1 | awk '{print $2}'
    fi
}


get-latest-version() {
    curl \
        -s \
        -o- \
        --url https://luarocks.github.io/luarocks/releases/ \
    | sed -n -r \
        -e 's/.*href="luarocks-([0-9.]+).tar.gz.*/\1/gp' \
    | sort -r --version-sort \
    | head -1
}

get-asset-download-url() {
    local -r version=$1
    echo "https://luarocks.github.io/luarocks/releases/luarocks-${version}.tar.gz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"

    tar xzf "$asset"

    cd "luarocks-${version}"

    ./configure \
        --prefix="$PREFIX" \
        --with-lua-bin="$PREFIX/bin" \
        --with-lua-include="$PREFIX/include" \
        --with-lua-lib="$PREFIX/lib" \

    make

    make install

    # luarocks won't install over top of existing files, so.... we gotta do this

    rsync -HavP \
        --delete \
        ./src/luarocks/ \
        "$PREFIX"/share/lua/5.1/luarocks/

}
