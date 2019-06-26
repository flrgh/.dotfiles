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
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# append to the history file, don't overwrite it
shopt -s histappend
