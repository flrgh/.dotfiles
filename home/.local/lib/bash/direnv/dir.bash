# shellcheck source=home/.local/lib/bash/stack.bash
source "$BASH_USER_LIB"/stack.bash

declare -g -a __DIRSTACK=()

dir::push() {
    local -r dest=${1:?}
    local -r old=${PWD:?}

    stack-push __DIRSTACK "$old"

    if [[ $old != "$dest" ]] && ! builtin cd "$dest"; then
        stack-pop __DIRSTACK || true
        fatal "failed to set working directory ($dest)"
    fi
}

dir::pop() {
    local REPLY

    if ! stack-pop __DIRSTACK; then
        fatal "directory stack is empty"
    fi

    local -r dest=${REPLY:?}
    local -r old=${PWD:?}

    if [[ $old != "$dest" ]] && ! builtin cd "$dest"; then
        fatal "failed to restore working directory ($dest)"
    fi
}
