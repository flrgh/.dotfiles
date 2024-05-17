#
# Tab completion
#

export BASH_COMPLETION_USER_DIR="$HOME/.local/share/bash-completion"

if [[ -f /etc/profile.d/bash_completion.sh ]]; then
    __rc_debug "sourcing system bash completion"
    __rc_source_file /etc/profile.d/bash_completion.sh
fi
