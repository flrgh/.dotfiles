#!/usr/bin/env bash

set -euo pipefail

source "$REPO_ROOT"/lib/bash/generate.bash

BASH_COMPLETION_USER_DIR="$HOME/.local/share/bash-completion"
bashrc-export-var BASH_COMPLETION_USER_DIR "$BASH_COMPLETION_USER_DIR"

BASH_COMPLETION_COMPAT_DIR="$HOME/.local/etc/bash_completion.d"
bashrc-export-var BASH_COMPLETION_COMPAT_DIR "$BASH_COMPLETION_COMPAT_DIR"

bashrc-unset-var BASH_COMPLETION_COMPAT_IGNORE

if [[ -f $BASH_COMPLETION_USER_DIR/bash_completion ]]; then
    __lazy_compgen() {
        complete -r -D
        unset -f __lazy_compgen

        source "${BASH_COMPLETION_USER_DIR:?}"/bash_completion

        _comp_complete_load "$@" && return 124
    }

    bashrc-include-function __lazy_compgen
    bashrc-includef 'function___lazy_compgen' \
        '%s\n' "complete -D -F __lazy_compgen"
fi
