#
# Tab completion
#

export BASH_COMPLETION_USER_DIR="$HOME/.local/share/bash-completion"

if [[ -f /etc/profile.d/bash_completion.sh ]]; then
    _debug_rc "sourcing system bash completion"
    _source_file /etc/profile.d/bash_completion.sh
fi
