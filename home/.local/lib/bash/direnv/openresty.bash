layout_openresty() {
    local dir="${1?OpenResty dir is required}"
    if [[ ! -d "$dir" ]]; then
        echo "ERROR: OpenResty not found at $dir"
        return
    fi

    echo "Using OpenResty at $dir"

    PATH_add "$dir"/bin
    PATH_add "$dir"/nginx/sbin

    PATH_add "$dir"/luajit/bin
    MANPATH_add "$dir"/luajit/share/man

    # variables used by Kong for special things
    export KONG_OPENRESTY_PATH="$dir"
    export KONG_TEST_OPENRESTY_PATH="$KONG_OPENRESTY_PATH"

    for lj in "$dir"/luajit/share/luajit-*; do
        add-lua-path "$lj"
    done

    add-lua-cpath "$dir"/luajit/lib

    add-lua-paths "$dir"/lualib
    add-lua-paths "$dir"/site/lualib
}
