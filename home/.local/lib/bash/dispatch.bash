BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}
source "$BASH_USER_LIB"/__init.bash
(( BASH_USER_LIB_SOURCED[dispatch]++ == 0 )) || return 0

__function_dispatch() {
    local -r fn=${FUNCNAME[1]:?could not detect function name}
    unset -f "$fn"

    # shellcheck disable=SC1090
    source "${BASH_USER_LIB}/functions/${fn}.bash"

    "$fn" "$@"
}
