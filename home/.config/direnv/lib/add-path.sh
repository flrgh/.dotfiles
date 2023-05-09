# it's like direnv's path_add function, but it supports custom separators
add-path() {
    local -r var="$1"
    local -r path="$2"
    local -r sep="${3:-;}"

    declare -a path_array
    IFS="${sep}" read -ra path_array <<<"${!var-}"

    local new="$path"

    for p in "${path_array[@]}"; do
        if [[ "$p" == "$path" ]]; then
            continue
        fi
        new="${new}${sep}${p}"
    done

    export "$var=$new"
}

add-lua-path() {
    local path="$1"

    path=$(realpath "$path")

    add-path LUA_PATH "$path/?/init.lua" ";"
    add-path LUA_PATH "$path/?.lua"      ";"
}

add-lua-cpath() {
    local path="$1"

    path=$(realpath "$path")

    add-path LUA_CPATH "$path/?.so" ";"
}

add-lua-paths() {
    local -r path="$1"

    add-lua-path "$path"
    add-lua-cpath "$path"
}


layout_openresty() {
    local dir="${1?OpenResty dir is required}"
    if [[ ! -d "$dir" ]]; then
        echo "ERROR: OpenResty not found at $dir"
        return 1
    fi

    echo "Using OpenResty at $dir"

    PATH_add "$dir"/bin
    PATH_add "$dir"/nginx/sbin

    PATH_add "$dir"/luajit/bin
    MANPATH_add "$dir"/luajit/share/man

    # variables used by Kong for special things
    export KONG_OPENRESTY_PATH="$dir"
    export KONG_TEST_OPENRESTY_PATH="$KONG_OPENRESTY_PATH"

    add-lua-paths "$dir"/lualib

    for lj in "$dir"/luajit/share/luajit-*; do
        add-lua-paths "$lj"
    done
}

layout_luarocks() {
    local dir="${1?LuaRocks dir is required}"
    if [[ ! -d "$dir" ]]; then
        echo "ERROR: LuaRocks dir not found!"
        return 1
    fi


    echo "Using LuaRocks at $dir"

    PATH_add "$dir/bin"
    add-lua-path "$dir/share/lua/5.1"
    add-lua-cpath "$dir/lib/lua/5.1"
}
