#!/usr/bin/env bash


if [[ -z ${INEED_DRIVERS:-} ]]; then
    declare -rg INEED_DRIVERS="$INEED_ROOT/drivers"
fi

function-exists() {
    declare -f "$1" &>/dev/null
}

binary-exists() {
    type -t "$1" &>/dev/null
}

list-drivers() {
    local -
    shopt -s nullglob

    for f in "$INEED_DRIVERS"/*.sh; do
        local name=${f##*/}
        name=${name%.sh}

        echo "$name"
    done
}

driver-exec() {
    local -r fn=$1
    local -r name=$2

    shift 2

    env \
        INEED_ROOT="$INEED_ROOT" \
        INEED_DRIVERS="$INEED_DRIVERS" \
        "$INEED_ROOT/driver-exec.sh" "$fn" "$name" "$@"
}

normalize-version() {
    local version=$1

    # trim leading v (v1.2.3 => 1.2.3)
    version=${version#v}

    echo "$version"
}
