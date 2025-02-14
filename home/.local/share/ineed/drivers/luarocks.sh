#!/usr/bin/env bash

set -euo pipefail

readonly NAME=luarocks
readonly PREFIX=$HOME/.local
readonly REPO=luarocks/luarocks
readonly BIN=$PREFIX/bin/luarocks

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        luarocks --version | head -1 | awk '{print $2}'
    fi
}


get-latest-version() {
    list-available-versions | head -1
}

list-available-versions() {
    gh-helper get-tag-names "$REPO" \
    | sort -r --version-sort
}


get-asset-download-url() {
    local -r version=$1
    echo "https://github.com/${REPO}/archive/refs/tags/v${version}.tar.gz"
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

    local lua_version
    if [[ -e config.unix ]]; then
        lua_version=$(sed -nre 's/LUA_VERSION=(.+)/\1/p' < config.unix)
    fi

    lua_version=${lua_version:-"5.1"}

    # this ensures that timestamps are preserved from the source code
    rsync -HavP \
        --delete \
        ./src/luarocks/ \
        "${PREFIX}/share/lua/${lua_version}/luarocks/"

    # update generated things
    local fname="$HOME/.local/bash/gen.d/luarocks"
    if [[ -e $fname ]]; then
        rm "$fname"
    fi

    touch "$fname"

    "$BIN" path --lr-path | tr ';' '\n' | while read -r elem; do
        if [[ "$elem" = */init.lua ]]; then
            other=${elem%/init.lua}.lua
            printf '__rc_add_path LUA_PATH --append --after %q %q\n' "$other" "$elem" >> "$fname"
        else
            other=${elem%.lua}/init.lua
            printf '__rc_add_path LUA_PATH --append --before %q %q\n' "$other" "$elem" >> "$fname"
        fi
    done

    "$BIN" path --lr-cpath | tr ';' '\n' | while read -r elem; do
        printf '__rc_add_path LUA_CPATH --append %q\n' "$elem" >> "$fname"
    done

    "$BIN" path --lr-bin | tr ';' '\n' | while read -r elem; do
        printf '__rc_add_path PATH %q\n' "$elem" >> "$fname"
    done
}
