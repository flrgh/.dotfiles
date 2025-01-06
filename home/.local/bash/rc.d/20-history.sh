# Bash History configuration

# turn off history expansion with !
set +H

# append to the history file, don't overwrite it
shopt -s histappend

# save multi-command one-liners as a single history item
shopt -s cmdhist

# * ignorespace => don't save commmands that start with a space
# * ignoredups  => don't save commands that match the most recent entry
export HISTCONTROL=ignorespace:ignoredups
#
# Don't save history commands
export HISTIGNORE='history:history *'

# History is valuable; let's keep lots of it
#
# Every time HISTFILESIZE is set, bash opens the history file and truncates it
# to the desired size, which slows down ~/.bashrc. This conditional makes it so
# that we don't perform that extra I/O on each shell init if the value doesn't
# need to be changed.
if (( HISTFILESIZE != 100000 )); then
    export HISTFILESIZE=100000
fi
export HISTSIZE=5000

# timestamps with history
export HISTTIMEFORMAT='%F %T '

export HISTFILE=$XDG_STATE_HOME/.bash_history

declare -gi __history_saved=0
declare -gi __history_index=0
declare -gr __history_prompt='\!'

__update_history() {
    # persist in-memory history items to the HISTFILE
    history -a

    # clear the in-memory history list
    history -c

    # re-read the HISTFILE into memory
    history -r

    #__history_index=$1
    __history_index=${__history_prompt@P}
    __history_saved=$EPOCHSECONDS
}

declare -gi __history_saving_enabled=1

# save+reload history after every command
# this could get expensive and slow when the history file gets big
__check_history() {
    if (( __history_saving_enabled == 0 )); then
        return
    fi

    local -ri idx=${__history_prompt@P}

    # we executed a new command: update the histfile
    if (( idx > __history_index )); then
        __update_history
        return
    fi

    if (( (EPOCHSECONDS - __history_saved) > 5 )); then
        local -i stat; stat=$(stat -c '%Y' "$HISTFILE")

        # the histfile hast been updated by somebody else--update!
        if (( stat > __history_saved )); then
            __update_history
            return
        fi
    fi
}

toggle_update_history() {
    if (( __history_saving_enabled == 0 )); then
        echo "history updating ENABLED"
        __history_saving_enabled=1
    else
        echo "history updating DISABLED"
        __history_saving_enabled=0
    fi
}

__rc_add_prompt_command "__check_history"
