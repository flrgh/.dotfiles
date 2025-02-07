#!/usr/bin/env bash

set -euo pipefail

source ./lib/bash/generate.bash

shopt -s extglob
shopt -s nullglob

declare -g REPLY

make_version_command() {
    local -r var=${1:?}
    local cmd="printf '%s.%s.%s'"
    local -i i
    for i in {0..2}; do
        printf -v cmd '%s "${%s[%s]:?}"' \
            "$cmd" "$var" "$i"
    done

    REPLY=$cmd
}

builtin_is_loadable() {
    local -r bash=${1:?}
    local -r path=${2:?}
    local -r name=${3:?}

    local cmd
    printf -v cmd \
        'enable -f %q %s' \
        "$path" \
        "$name"

    "$bash" -c "$cmd" &>/dev/null
}

get_builtin_version() {
    local -r bash=${1:?}
    local -r path=${2:?}
    local -r name=${3:?}

    local cmd
    printf -v cmd \
        'enable -f %q %s' \
        "$path" \
        "$name"

    make_version_command "${name^^}_VERSION"
    cmd="${cmd}; ${REPLY}"

    "$bash" -c "$cmd" 2>/dev/null || echo "0.0.0"
}

bash_facts() {
    local -r lib=$HOME/.local/lib/bash
    local bin

    if [[ -x $HOME/.local/bin/bash ]]; then
        set-have local-bash
        bin=$HOME/.local/bin/bash
    else
        set-not-have local-bash
        bin=$(command -v -p bash)
    fi

    set-location bash "${bin:?}"

    local cmd
    make_version_command BASH_VERSINFO
    cmd=$REPLY

    local version; version=$("$bin" -c "$cmd")

    set-have bash "$version"

    local builtins
    if [[ -d $lib/loadables ]]; then
        builtins="$lib/loadables"

    elif [[ -d $lib/builtins ]]; then
        builtins="$lib/builtins"
    fi

    set-not-have builtins-timer
    set-not-have builtins-version
    set-not-have builtins-varsplice
    set-not-have builtins-stat

    if [[ -n ${builtins:-} ]]; then
        set-location bash-builtins "$lib/loadables"

        for path in "$builtins"/*; do
            local name=${path##*/}

            if [[ $name = *.so ]]; then
                # handle old `lib{name}.so` files
                name=${name#lib}
                name=${name%.so}
            fi

            if ! builtin_is_loadable "$bin" "$path" "$name"; then
                set-not-have "builtins-${name}"
                continue
            fi

            version=$(get_builtin_version "$bin" "$path" "$name")
            set-have "builtins-${name}" "$version"
            set-location "builtins-${name}" "$path"
        done
    fi
}

main() {
    rc-init
    bash_facts
}

main "$@"
