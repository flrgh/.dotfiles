# Bash History configuration

# turn off history expansion with !
set +H

# append to the history file, don't overwrite it
shopt -s histappend

# save multi-command one-liners as a single history item
shopt -s cmdhist

# Don't save commmands that start with a space
export HISTCONTROL=ignorespace
# ...otherwise, keep everything
unset HISTIGNORE

# History is valuable; let's keep lots of it
export HISTFILESIZE=100000
export HISTSIZE=5000

# timestamps with history
export HISTTIMEFORMAT='%F %T '

export HISTFILE=$XDG_STATE_HOME/.bash_history

declare -gi __history_saved=0

# save+reload history after every command
# this could get expensive and slow when the history file gets big
__update_history() {
    local -i now
    printf -v now '%(%s)T'

    if (( (now - __history_saved) > 5 )); then
        # persist in-memory history items to the HISTFILE
        history -a

        # clear the in-memory history list
        history -c

        # re-read the HISTFILE into memory
        history -r

        __history_saved=$now
    fi
}

__rc_add_prompt_command "__update_history"
