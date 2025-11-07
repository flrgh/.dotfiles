assert::pwd() {
    local -r exp=${1:?}

    if [[ $PWD != "$exp" ]]; then
        fatal "${2:-"\$PWD ($PWD) != expected ($exp)"}" "${3:-0}"
    fi
}

assert::function() {
    local -r fn=${1:?}

    if ! builtin declare -f "$fn" &>/dev/null; then
        fatal "${2:-"function '$fn' not found"}" "${3:-0}"
    fi
}

assert::has() {
    if (( $# < 1 )); then
        fatal "called with no arguments"
    fi

    local -a missing=()
    local bin
    for bin in "$@"; do
        if ! has "$bin"; then
            missing+=("$bin")
        fi
    done

    if (( ${#missing[@]} )); then
        fatal "missing required tools: ${missing[*]}"
    fi
}
