BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}
source "$BASH_USER_LIB"/__init.bash
(( BASH_USER_LIB_SOURCED[stack]++ == 0 )) || return 0

stack-push() {
    declare -nI __ref=${1:?}
    local -r value=${2:?}
    __ref+=( "$value" )
}

stack-pop() {
    declare -nI __ref=${1:?}

    unset REPLY
    declare -g REPLY

    local -i last=$(( ${#__ref[@]} - 1 ))

    if (( last < 0 )); then
        return 1
    fi

    REPLY="${__ref[*]: $last}"

    __ref=( "${__ref[@]:0:$last}" )

    return 0
}
