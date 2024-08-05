# shellcheck source=home/.local/lib/bash/array.bash
source "$BASH_USER_LIB"/array.bash

# it's like direnv's path_add function, but it supports custom separators
#
# unlike the one in my .bashrc, it always prepends the input path to the
# destination var instead of just checking if it's already present
# (TODO: maybe my .bashrc should use this?)
add-path() {
    local -r var="$1"
    local -r path="$2"
    local -r sep="${3:-;}"

    if [[ -z "${!var:-}" ]]; then
        export "$var=$path"
        return
    fi

    local -a old
    IFS="${sep}" read -ra old <<<"${!var-}"

    local -a new=("$path")

    for p in "${old[@]}"; do
        if [[ "$p" == "$path" ]]; then
            continue
        fi
        new+=("$p")
    done

    array-join-var "$var" "$sep" "${new[@]}"

    # required for direnv
    export "$var=${!var}"
}

add-lua-path() {
    local path="$1"

    path=$(realpath -m "$path")

    add-path LUA_PATH "$path/?/init.lua"  ";"
    add-path LUA_PATH "$path/?.lua"       ";"
}

add-luajit-path() {
    local path="$1"

    path=$(realpath -m "$path")

    # prepend .ljbc files first so that plain .lua files will override them
    add-path LUA_PATH "$path/?/init.ljbc" ";"
    add-path LUA_PATH "$path/?.ljbc"      ";"

    add-path LUA_PATH "$path/?/init.lua"  ";"
    add-path LUA_PATH "$path/?.lua"       ";"
}

add-lua-cpath() {
    local path="$1"

    path=$(realpath -m "$path")

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
