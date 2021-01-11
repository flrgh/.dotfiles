# luarocks config
export LUAROCKS_CONFIG=$CONFIG_HOME/luarocks/config.lua

# init script for the lua REPL
if [[ -f $CONFIG_HOME/lua/repl.lua ]]; then
    export LUA_INIT="@$CONFIG_HOME/lua/repl.lua"
fi

set_luarocks_path() {
    local now file mtime

    if iHave luarocks; then
        printf -v now '%(%s)T'
        unset LUA_PATH LUA_CPATH

        file="$CACHE_DIR/luarocks-paths"
        if [[ -f $file && -s $file ]]; then
            _debug_rc "luarocks path cache exists"
            mtime=$(stat --format='%Y' "$file")
            if (( mtime + (24*60*60) < now )); then
                _debug_rc "luarocks path cache is stale--rebuilding"
                rm "$file"
                luarocks path --no-bin > "$file"
            fi

        else
            _debug_rc "Creating luarocks path cache"
            luarocks path --no-bin > "$file"
        fi

        . "$file"
    fi

    unset -f set_luarocks_path
}

set_luarocks_path
