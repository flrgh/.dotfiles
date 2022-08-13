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
