#!/usr/bin/env bash

# my bash standard library

# check if a function exists
function-exists() {
    builtin declare -f "$1" &>/dev/null
}

# check if a binary exists
binary-exists() {
    builtin type -f -t "$1" &>/dev/null
}

# check if a command exists (can be a function, alias, or binary)
command-exists() {
    builtin type -t "$1" &>/dev/null
}

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
