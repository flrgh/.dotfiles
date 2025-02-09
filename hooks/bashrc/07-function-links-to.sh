#!/usr/bin/env bash

set -euo pipefail

source ./lib/bash/generate.bash

shopt -s extglob
shopt -s nullglob

rc-new-workfile "function-links-to"
rc-workfile-add-dep "$RC_DEP_BUILTINS"

if have-builtin stat; then
    rc-workfile-add-exec __rc_debug \
        'links-to(): using stat builtin'

    links-to() {
        local -r path=${1:?}
        local -r target=${2:?}

        builtin stat -L "$path" || return 1
        [[ ${STAT[type]:-} == 'l' && ${STAT[link]:-} == "$target" ]]
    }

else
    rc-workfile-add-exec __rc_debug \
        'links-to(): using stat command'

    links-to() {
        local -r path=${1:?}
        local -r target=${2:?}

        if [[ ! -e $path ]]; then
            return 1
        fi

        local out
        out=$(command -p stat -c '%N' "$path") || return 1
        if [[ -z ${out:-} ]]; then
            return 1
        fi

        # output is something like:
        # '/path/to/src' -> '/path/to/target'
        local -r split="' -> '"
        out=${out#*"$split"}
        out=${out: 0:-1}

        [[ $target == "$out" ]]
    }
fi

rc-workfile-add-function links-to
rc-workfile-close
