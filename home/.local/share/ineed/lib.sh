#!/usr/bin/env bash


if [[ -z ${INEED_DRIVERS:-} ]]; then
    declare -rg INEED_DRIVERS="$INEED_ROOT/drivers"
fi


if [[ -z ${INEED_STATE:-} ]]; then
    declare -rgx INEED_STATE="$HOME/.local/state/ineed"
fi

declare -gi S_MINUTE=60
declare -gi S_HOUR=$(( S_MINUTE * 60 ))
declare -gi S_DAY=$(( 24 * S_HOUR ))
declare -gi S_YEAR=$(( 365 * S_DAY ))

friendly-time-since() {
    local -r stamp=$1

    local unix; unix=$(date -d "$stamp" +%s)
    local -i diff=$(( EPOCHSECONDS - unix ))

    local years=$(( diff / S_YEAR ))
    diff=$(( diff % S_YEAR ))
    #local months=0

    local days=$(( diff / S_DAY ))
    diff=$(( diff % S_DAY ))

    local hours=$((   diff / S_HOUR   ))
    diff=$(( diff % S_HOUR ))

    local minutes=$(( diff / S_MINUTE ))
    diff=$(( diff % S_MINUTE ))

    local seconds=$diff

    local fmt
    local -a args

    if (( years > 0 )); then
        fmt='%d years, %03d days'
        args=( "$years" "$days")

    elif (( days > 0 )); then
        fmt='%d days, %02d hours'
        args=( "$days" "$hours")

    elif (( hours > 0 )); then
        fmt='%02d hours, %02d minutes'
        args=( "$hours" "$minutes" )

    elif (( minutes > 0 )); then
        fmt='%02d minutes, %02d seconds'
        args=( "$minutes" "$seconds" )

    else
        fmt='%d seconds'
        args=( "$seconds" )
    fi

    printf "$fmt" "${args[@]}"
}

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

driver-exec-quiet() {
    driver-exec "$@" 2&>/dev/null
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

app-state::list() {
    local -r app=$1

    local -r prefix="$INEED_STATE/${app}."

    printf '%s\n' "$app"

    local key value

    shopt -s nullglob
    for fname in "$prefix"*; do
        key=${fname#"$prefix"}
        value=$(< "$fname")

        printf '%-32s => %-32s\n' "$key" "$value"
    done
}
