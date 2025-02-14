#!/usr/bin/env bash

set -euo pipefail

source ./lib/bash/generate.bash

rc-new-workfile "completion"
rc-workfile-add-dep "$RC_DEP_SET_VAR"

BASH_COMPLETION_USER_DIR="$HOME/.local/share/bash-completion"
rc-export BASH_COMPLETION_USER_DIR "$BASH_COMPLETION_USER_DIR"

BASH_COMPLETION_COMPAT_DIR="$HOME/.local/etc/bash_completion.d"
rc-export BASH_COMPLETION_COMPAT_DIR "$BASH_COMPLETION_COMPAT_DIR"

rc-unset BASH_COMPLETION_COMPAT_IGNORE

if [[ -f $BASH_COMPLETION_USER_DIR/bash_completion ]]; then
    __lazy_compgen() {
        complete -r -D
        unset -f __lazy_compgen

        source "${BASH_COMPLETION_USER_DIR:?}"/bash_completion

        _comp_complete_load "$@" && return 124
    }

    rc-workfile-if-interactive
    rc-workfile-add-function __lazy_compgen
    rc-workfile-add-exec complete -D -F __lazy_compgen
    rc-workfile-fi
fi

rc-workfile-close
