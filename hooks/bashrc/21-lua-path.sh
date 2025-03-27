#!/usr/bin/env bash

set -euo pipefail
source ./lib/bash/generate.bash

emit-lua-vars() {
    rc-set-exported LUA_PATH
    rc-set-exported LUA_CPATH
}

emit-luarocks() {
    local conf=$INSTALL_PATH/.config/luarocks/config.lua
    if [[ -f $conf ]]; then
        rc-export LUAROCKS_CONFIG "$conf"
    fi

    if ! command -v luarocks &>/dev/null; then
        echo "luarocks not installed, exiting"
        return 0
    fi

    luarocks path --lr-path | tr ';' '\n' | while read -r elem; do
        if [[ "$elem" = */init.lua ]]; then
            other=${elem%/init.lua}.lua
            rc-add-path LUA_PATH --append --after "$other" "$elem"
        else
            other=${elem%.lua}/init.lua
            rc-add-path LUA_PATH --append --before "$other" "$elem"
        fi
    done

    luarocks path --lr-cpath | tr ';' '\n' | while read -r elem; do
        rc-add-path LUA_CPATH --append "$elem"
    done

    luarocks path --lr-bin | tr ';' '\n' | while read -r elem; do
        rc-add-path PATH "$elem"
    done
}

emit-lua-utils() {
    local -r lua_utils=$HOME/git/flrgh/lua-utils

    if [[ ! -d $lua_utils ]]; then
        echo "lua utils ($lua_utils) not found, exiting"
        exit 0
    fi

    rc-add-path --prepend LUA_PATH \
        "$lua_utils/lib/?/init.lua"

    rc-add-path --prepend LUA_PATH \
        "$lua_utils/lib/?.lua"
}

emit-luajit-path() {
    local path=$HOME/.local/share/luajit-2.1

    if [[ -d $path ]]; then
        rc-add-path LUA_PATH "${path}/?.lua"
    fi
}

emit-lua-init() {
    # init script for the lua REPL
    local fname=$INSTALL_PATH/.config/lua/repl.lua

    if [[ -f $fname ]]; then
        rc-export LUA_INIT "@$fname"
    fi
}

emit-lua-vars
emit-luarocks
emit-lua-utils
emit-luajit-path
emit-lua-init
