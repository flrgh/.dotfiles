#!/usr/bin/env bash

set -euo pipefail

readonly PREFIX=$HOME/.local

is-installed() {
    binary-exists lua
}

get-installed-version() {
    if is-installed; then
        lua -v 2>&1 | awk '{print $2}'
    fi
}

get-latest-version() {
    list-available-versions | head -1
}

list-available-versions() {
    curl \
        -s \
        -o- \
        --url https://www.lua.org/ftp/ \
    | sed -n -r \
        -e 's/.*HREF="lua-([0-9.]+).tar.gz".*/\1/gp' \
    | sort -n -r
}


get-asset-download-url() {
    local -r version=$1
    echo "https://www.lua.org/ftp/lua-${version}.tar.gz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"
    echo "build temp directory: $PWD"

    tar --strip-components 1 \
        --extract \
        --gzip \
        --file "$asset"

    local -a env=(
        PLAT=linux
        INSTALL_TOP="$HOME/.local"
        INSTALL_BIN="$HOME/.local/bin"
        INSTALL_INC="$HOME/.local/include"
        INSTALL_LIB="$HOME/.local/lib"
        INSTALL_MAN="$HOME/.local/share/man/man1"
    )

    make echo "${env[@]}"
    make linux install "${env[@]}"
}
