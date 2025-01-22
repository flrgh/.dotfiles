#!/usr/bin/env bash

set -euo pipefail
source "$REPO_ROOT"/lib/bash/generate.bash

append() {
    bashrc-includef "lua-path" "$@"
}

emit-luarocks() {
    local conf=$INSTALL_PATH/.config/luarocks/config.lua
    if [[ -f $conf ]]; then
        bashrc-export-var LUAROCKS_CONFIG "$conf"
    fi

    if ! command -v luarocks &>/dev/null; then
        echo "luarocks not installed, exiting"
        return 0
    fi

    append '# luarocks paths\n'

    luarocks path --lr-path | tr ';' '\n' | while read -r elem; do
        if [[ "$elem" = */init.lua ]]; then
            other=${elem%/init.lua}.lua
            append '__rc_add_path LUA_PATH --append --after %q %q\n' "$other" "$elem"
        else
            other=${elem%.lua}/init.lua
            append '__rc_add_path LUA_PATH --append --before %q %q\n' "$other" "$elem"
        fi
    done

    luarocks path --lr-cpath | tr ';' '\n' | while read -r elem; do
        append '__rc_add_path LUA_CPATH --append %q\n' "$elem"
    done

    luarocks path --lr-bin | tr ';' '\n' | while read -r elem; do
        append '__rc_add_path PATH %q\n' "$elem"
    done
}

emit-lua-utils() {
    local -r lua_utils=$HOME/git/flrgh/lua-utils

    if [[ ! -d $lua_utils ]]; then
        echo "lua utils ($lua_utils) not found, exiting"
        exit 0
    fi

    append '# ~/git/flrgh/lua-utils paths\n'

    append '__rc_add_path --prepend LUA_PATH %q\n' \
        "$lua_utils/lib/?/init.lua"

    append '__rc_add_path --prepend LUA_PATH %q\n' \
        "$lua_utils/lib/?.lua"
}

emit-luajit-path() {
    local path=$HOME/.local/share/luajit-2.1

    if [[ -d $path ]]; then
        append '__rc_add_path LUA_PATH %q\n' "${path}/?.lua"
    fi
}

emit-lua-init() {
    # init script for the lua REPL
    local fname=$INSTALL_PATH/.config/lua/repl.lua

    if [[ -f $fname ]]; then
        bashrc-export-var LUA_INIT "@$fname"
    fi
}

emit-luarocks
emit-lua-utils
emit-luajit-path
emit-lua-init
