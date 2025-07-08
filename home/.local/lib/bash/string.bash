declare -g BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}
source "$BASH_USER_LIB"/__init.bash
(( BASH_USER_LIB_SOURCED[string]++ == 0 )) || return 0

source "$BASH_USER_LIB"/dispatch.bash

ltrim() {
    local -n ref=${1:?var name required}
    local -r pat=${2:-"[[:space:]]"}

    local -i reset=0
    if ! shopt -q extglob; then
        shopt -s extglob
        reset=1
    fi

    # shellcheck disable=SC2295
    ref=${ref##+($pat)}

    if (( reset == 1 )); then
        shopt -u extglob
    fi
}

rtrim() {
    local -n ref=${1:?var name required}
    local -r pat=${2:-"[[:space:]]"}

    local -i reset=0
    if ! shopt -q extglob; then
        shopt -s extglob
        reset=1
    fi

    # shellcheck disable=SC2295
    ref=${ref%%+($pat)}

    if (( reset == 1 )); then
        shopt -u extglob
    fi
}

strip-whitespace() {
    __function_dispatch "$@"
}
