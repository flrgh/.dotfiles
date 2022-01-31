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
    local -r path="$1"

    add-path LUA_PATH "$path/?/init.lua" ";"
    add-path LUA_PATH "$path/?.lua"      ";"

    add-path LUA_CPATH "$path/?.so" ";"
}
