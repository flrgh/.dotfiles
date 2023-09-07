#!/usr/bin/env bash


if [[ -z ${INEED_DRIVERS:-} ]]; then
    declare -rg INEED_DRIVERS="$INEED_ROOT/drivers"
fi


if [[ -z ${INEED_STATE:-} ]]; then
    declare -rgx INEED_STATE="$HOME/.local/state/ineed"
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

state::get() {
    local -r name=$1
    local -r fname="$INEED_STATE/$name"

    if [[ -f $fname ]]; then
        cat "$fname"

    else
        return 1
    fi
}

state::set() {
    local -r name=$1
    local -r value=$2

    local -r fname="$INEED_STATE/$name"

    mkdir -p "$INEED_STATE"

    printf '%s' "$value" > "$fname"
}

app-state::get() {
    local -r app=$1
    local -r key=$2

    state::get "${app}.${key}"
}

app-state::set() {
    local -r app=$1
    local -r key=$2
    local -r value=$3

    state::set "${app}.${key}" "$value"
}
