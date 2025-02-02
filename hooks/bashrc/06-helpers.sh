#!/usr/bin/env bash

set -euo pipefail

source "$REPO_ROOT"/lib/bash/generate.bash

shopt -s extglob
shopt -s nullglob

DEST=links-to

if have stat; then
    get-location stat
    stat=${FACT:?}

    bashrc-pref "$DEST" 'enable -f %q stat\n' "$stat"
    bashrc-pref "$DEST" 'enable -n stat\n'
    bashrc-pref "$DEST" '__rc_debug %q\n' \
        'links-to(): using stat builtin'

    links-to() {
        local -r path=${1:?}
        local -r target=${2:?}

        builtin stat -L "$path" || return 1
        [[ ${STAT[type]:-} == 'l' && ${STAT[link]:-} == "$target" ]]
    }

else
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

bashrc-pref "$DEST" '%s\n' "$(bashrc-dump-function links-to)"
