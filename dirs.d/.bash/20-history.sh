# Bash History configuration

# Don't save commmands that start with a space
export HISTCONTROL=ignorespace

# History is valuable; let's keep lots of it
export HISTFILESIZE=100000
export HISTSIZE=1000

# timestamps with history
export HISTTIMEFORMAT='%F %T '

# save+reload history after every command
# this could get expensive and slow when the history file gets big
_HISTORY_CMD="history -a; history -c; history -r;"
_debug_rc "Prompt command: $PROMPT_COMMAND"
if ! [[ $PROMPT_COMMAND == *${_HISTORY_CMD}* ]]; then
    _debug_rc "Prepending history command ($_HISTORY_CMD) to \$PROMPT_COMMAND"
    export PROMPT_COMMAND="$_HISTORY_CMD $PROMPT_COMMAND"
fi

# append to the history file, don't overwrite it
shopt -s histappend
