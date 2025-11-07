BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}
source "$BASH_USER_LIB"/__init.bash
(( BASH_USER_LIB_SOURCED[trace]++ == 0 )) || return 0

trace() {
    local -i level=${1:-0}
    local -i i

    for (( i = level; i < ${#BASH_LINENO[@]}; i++ )); do
        printf '%2d %-48s:%-3d %s\n' \
            "$i" \
            "${BASH_SOURCE[i]}" \
            "${BASH_LINENO[i]}" \
            "${FUNCNAME[i]}"
    done
}
