BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}
source "$BASH_USER_LIB"/__init.bash
(( BASH_USER_LIB_SOURCED[array]++ == 0 )) || return 0

# join array elements by some delimiter and save the resulting
# string to a variable
#
# example:
#
# ```bash
#   items=(a b c d e)
#   array-join-var result '|' "${items[@]}"
#   echo "$result"
# ```
array-join-var() {
    local var=$1
    local delim=${2-}
    local first=${3-}

    if shift 3; then
        printf -v "$var" '%s' "$first" "${@/#/$delim}"
    fi
}

# join array elements by some delimiter and print the resulting
# string to stdout, with a trailing newline
#
# example:
#
# ```bash
#   items=(a b c d e)
#   array-join '|' "${items[@]}"
# ```
array-join() {
    if (( $# < 1 )); then
        return 1
    fi

    local result
    array-join-var result "$@"
    printf '%s\n' "$result"
}

array-contains() {
    local -r search=${1:-?need a value to search for}
    shift

    for arg in "$@"; do
        if [[ $arg == "$search" ]]; then
            return 0
        fi
    done

    return 1
}
