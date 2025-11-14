BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}
source "$BASH_USER_LIB"/__init.bash
(( BASH_USER_LIB_SOURCED[trace]++ == 0 )) || return 0

trace() {
    local -i level=${1:-0}
    local -i i

    local -i slen=8

    for (( i = level + 1; i < ${#BASH_SOURCE[@]}; i++ )); do
        local src=${BASH_SOURCE[i]}
        slen=$(( (${#src} > slen) ? ( ${#src} + 2 ) : slen ))
    done

    for (( i = level + 1; i < ${#BASH_SOURCE[@]}; i++ )); do
        builtin printf \
            "%2d %-${slen}s :%-5d %s\n" \
            "$(( i - level - 1))" \
            "${BASH_SOURCE[i]}" \
            "${BASH_LINENO[i - 1]}" \
            "${FUNCNAME[i]}"
    done

}
