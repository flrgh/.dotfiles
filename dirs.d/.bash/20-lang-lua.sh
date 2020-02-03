# luarocks config
export LUAROCKS_CONFIG=$CONFIG_HOME/luarocks/config.lua

# init script for the lua REPL
if [[ -f $CONFIG_HOME/lua/repl.lua ]]; then
    export LUA_INIT="@$CONFIG_HOME/lua/repl.lua"
fi

if iHave luarocks; then
    printf -v _now '%(%s)T'

    file="$CACHE_DIR/luarocks-paths"
    if [[ -f $file ]]; then
        _debug_rc "luarocks path cache exists"
        mtime=$(stat --format='%Y' "$file")
        if (( mtime + (24*60*60) < _now )); then
            _debug_rc "luarocks path cache is stale--rebuilding"
            rm "$file"
            luarocks path --lr-path > "$file"
            luarocks path --lr-cpath >> "$file"
        fi

    else
        _debug_rc "Creating luarocks path cache"
        luarocks path --lr-path > "$file"
        luarocks path --lr-cpath >> "$file"
    fi

    addPath "$(head -1 "$file")" "LUA_PATH" ";"
    addPath "$(tail -1 "$file")" "LUA_CPATH" ";"
fi
