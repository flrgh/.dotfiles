# shellcheck source=home/.local/lib/bash/array.bash
source "$BASH_USER_LIB"/array.bash

if [[ -e "$BASH_USER_LIB"/builtins.bash ]] \
    && source "$BASH_USER_LIB"/builtins.bash \
    && (( BASH_USER_BUILTINS["varsplice"] == 1 ))
then
    add-path() {
        local -r var="$1"
        local -r path="$2"
        local -r sep="${3:-;}"

        varsplice -s "$sep" --prepend --move "$var" "$path"

        # required for direnv
        export "$var=${!var}"
    }

else
    # it's like direnv's path_add function, but it supports custom separators
    #
    # unlike the one in my .bashrc, it always prepends the input path to the
    # destination var instead of just checking if it's already present
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
fi

add-lua-path() {
    local path="$1"

    #path=$(realpath -m "$path")

    add-path LUA_PATH "$path/?/init.lua"  ";"
    add-path LUA_PATH "$path/?.lua"       ";"
}

add-luajit-path() {
    local path="$1"

    #path=$(realpath -m "$path")

    # prepend .ljbc files first so that plain .lua files will override them
    add-path LUA_PATH "$path/?/init.ljbc" ";"
    add-path LUA_PATH "$path/?.ljbc"      ";"

    add-path LUA_PATH "$path/?/init.lua"  ";"
    add-path LUA_PATH "$path/?.lua"       ";"
}

add-lua-cpath() {
    local path="$1"

    #path=$(realpath -m "$path")

    add-path LUA_CPATH "$path/?.so" ";"
}

add-lua-paths() {
    local -r path="$1"

    add-lua-path "$path"
    add-lua-cpath "$path"
}
