#
# Tab completion
#

export BASH_COMPLETION_USER_DIR="$HOME/.local/share/bash-completion"
export BASH_COMPLETION_COMPAT_DIR="$HOME/.local/etc/bash_completion.d"
unset BASH_COMPLETION_COMPAT_IGNORE

if [[ -f $BASH_COMPLETION_USER_DIR/bash_completion ]]; then
    __lazy_compgen() {
        complete -r -D
        unset -f __lazy_compgen

        source "$BASH_COMPLETION_USER_DIR"/bash_completion

        _comp_complete_load "$@" && return 124
    }

    complete -D -F __lazy_compgen
fi
