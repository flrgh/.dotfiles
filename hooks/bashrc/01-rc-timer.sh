#!/usr/bin/env bash

set -euo pipefail

source "$REPO_ROOT"/lib/bash/generate.bash
source "$REPO_ROOT"/lib/bash/facts.bash

readonly DEST=01-timer

bashrc-pref "$DEST" '%s\n' 'if (( DEBUG_BASHRC > 0 )); then'

if have timer && get-location timer; then
    lib=${FACT:?}
    bashrc-pre-exec "$DEST" \
        enable -f "$lib" timer

    bashrc-pre-include-file "$REPO_ROOT"/bash/rc_timer_new.bash "${DEST}.sh"

else
    bashrc-pre-include-file "$REPO_ROOT"/bash/rc_timer_old.bash "${DEST}.sh"
fi

bashrc-pref "$DEST" '%s\n' 'fi'
