#
# Tab completion
#

export BASH_COMPLETION_USER_DIR="$HOME/.local/share/bash-completion"
export BASH_COMPLETION_COMPAT_DIR="$HOME/.local/etc/bash_completion.d"
unset BASH_COMPLETION_COMPAT_IGNORE

if [[ -f $BASH_COMPLETION_USER_DIR/bash_completion ]]; then
    __rc_source_file "$BASH_COMPLETION_USER_DIR"/bash_completion

elif [[ -f /etc/profile.d/bash_completion.sh ]]; then
    __rc_source_file /etc/profile.d/bash_completion.sh
fi
