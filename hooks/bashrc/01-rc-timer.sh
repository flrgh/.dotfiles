#!/usr/bin/env bash

set -euo pipefail

source "$REPO_ROOT"/lib/bash/generate.bash

readonly DEST=01-timer

HAVE_TIMER=0
if [[ -e $HOME/.local/lib/bash/builtins.bash ]]; then
    source "$HOME/.local/lib/bash/builtins.bash"
    HAVE_TIMER=${BASH_USER_BUILTINS[timer]:-0}
fi

bashrc-pref "$DEST" '%s\n' 'if (( DEBUG_BASHRC > 0 )); then'

if (( HAVE_TIMER == 1 )); then
    lib="${BASH_USER_BUILTINS_SOURCE[timer]}"
    bashrc-pre-exec "$DEST" \
        enable -f "${lib:?empty timer lib source}" timer

    bashrc-pre-include-file "$REPO_ROOT"/bash/rc_timer_new.bash "${DEST}.sh"

else
    bashrc-pre-include-file "$REPO_ROOT"/bash/rc_timer_old.bash "${DEST}.sh"
fi

bashrc-pref "$DEST" '%s\n' 'fi'
