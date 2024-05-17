# Bash History configuration

# Don't save commmands that start with a space
export HISTCONTROL=ignorespace

# History is valuable; let's keep lots of it
export HISTFILESIZE=100000
export HISTSIZE=5000

# timestamps with history
export HISTTIMEFORMAT='%F %T '

export HISTFILE=$XDG_STATE_HOME/.bash_history

__HIST_SAVED=0

# save+reload history after every command
# this could get expensive and slow when the history file gets big
__update_history() {
    local -i now
    printf -v now '%(%s)T'

    if (( (now - __HIST_SAVED) > 5 )); then
        # persist in-memory history items to the HISTFILE
        history -a

        # clear the in-memory history list
        history -c

        # re-read the HISTFILE into memory
        history -r

        __HIST_SAVED=$now
    fi
}

__rc_add_path "__update_history" "PROMPT_COMMAND" ";"

# append to the history file, don't overwrite it
shopt -s histappend

# turn off history expansion with !
set +H
