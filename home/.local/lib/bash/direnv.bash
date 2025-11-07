# shellcheck disable=SC2059

declare -g BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}

log::error() {
    if (( $# == 1 )); then
        log_error "$1"
    else
        local __msg
        printf -v __msg "$@"
        log_error "$__msg"
    fi
}

log::status() {
    if (( $# == 1 )); then
        log_status "$1"
    else
        local __msg
        printf -v __msg "$@"
        log_status "$__msg"
    fi
}

log::trace() {
    local -ri level=${1:-0}
    local -i i

    log::error "TRACE:"

    for (( i = level + 1; i < ${#BASH_SOURCE[@]}; i++ )); do
        log::error '  %2d  %-48s:%-5d  %-24s' \
            "$(( i - level - 1))" \
            "${BASH_SOURCE[i]}" \
            "${BASH_LINENO[i - 1]}" \
            "${FUNCNAME[i]}"
    done
}

fatal() {
    local -r msg=${1:?}
    local -i level=${2:-0}
    local -ri level=$(( level + 2 ))

    log::error "FATAL: $msg"
    log::trace "$level"

    exit 99
}

__bash_direnv_lazy() {
    local -r fn=${FUNCNAME[1]:?could not detect function name}

    local -r lib=${1:?no namespace name provided}
    shift

    local src
    if [[ ${lib:0:1} == "/" ]]; then
        src=$lib
    else
        src=${BASH_DIRENV_LIB}/${lib}.bash
    fi

    watch_file "$src"

    if [[ ! -r $src ]]; then
        fatal "source file for function ${fn} ($src) does not exist"
    fi

    builtin unset -f "$fn"

    builtin unset -f __lazy_init || true

    # shellcheck disable=SC1090
    builtin source "$src"

    if declare -F __lazy_init &>/dev/null; then
        if ! __lazy_init; then
            fatal "$src lazy init returned non-zero"
        fi
        builtin unset -f __lazy_init || true
    fi

    if ! builtin declare -F "$fn" &>/dev/null; then
        fatal "function ${fn} not defined by source file ($src)"
    fi

    "$fn" "$@"
}
