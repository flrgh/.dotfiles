layout_luarocks() {
    local dir="${1?LuaRocks dir is required}"
    if [[ ! -d "$dir" ]]; then
        echo "ERROR: LuaRocks dir not found!"
        return
    fi

    echo "Using LuaRocks at $dir"

    PATH_add "$dir/bin"
    add-luajit-path "$dir/share/lua/5.1"
    add-lua-cpath "$dir/lib/lua/5.1"
}
