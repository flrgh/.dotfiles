#!/usr/bin/env bash

set -euo pipefail

source "$REPO_ROOT"/lib/bash/generate.bash

readonly DEST=01-timer

append() {
    bashrc-pref "$DEST" "$@"
}

add-function() {
    local -r name=$1

    local body
    if body=$(declare -f "$name" 2>/dev/null); then
        append '%s\n' "$body"

    else
        echo "function $name not found"
    fi
}

add-call() {
    bashrc-pre-exec "$DEST" "$@"
}

__rc_have_timer=0
if [[ -e $HOME/.local/lib/bash/builtins.bash ]]; then
    source "$HOME/.local/lib/bash/builtins.bash"
    __rc_have_timer=${BASH_USER_BUILTINS[timer]:-0}
fi

if (( __rc_have_timer == 1 )); then
    lib="${BASH_USER_BUILTINS_SOURCE[timer]}"
    append 'if (( DEBUG_BASHRC > 0 )); then\n'
    add-call enable -f "${lib:?empty timer lib source}" timer
    bashrc-pre-include-file "$REPO_ROOT"/bash/rc_timer_new.bash "${DEST}.sh"
    append 'fi\n'

else
    append 'if (( DEBUG_BASHRC > 0 )); then\n'
    bashrc-pre-include-file "$REPO_ROOT"/bash/rc_timer_old.bash "${DEST}.sh"
    append 'fi\n'
fi
