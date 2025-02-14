declare -gi __history_saved=0
declare -gi __history_index=0
declare -gi __history_checked=0
declare -gr __history_prompt='\!'
declare -gi __history_saving_enabled=1

toggle_update_history() {
    if (( __history_saving_enabled == 0 )); then
        echo "history updating ENABLED"
        __history_saving_enabled=1
    else
        echo "history updating DISABLED"
        __history_saving_enabled=0
    fi
}

# save+reload history after every command
# this could get expensive and slow when the history file gets big
__check_history() {
    local ec=$?
    if (( __history_saving_enabled == 0 )); then
        return "$ec"
    fi

    local -ri idx=${__history_prompt@P}
    local -i update=0

    # we executed a new command: update the histfile
    if (( idx > __history_index )); then
        update=1

    elif (( (EPOCHSECONDS - __history_checked) > 5 )); then
        __history_checked=$EPOCHSECONDS

        __get_mtime "$HISTFILE" || true
        local -i stat=$REPLY

        # the histfile hast been updated by somebody else--update!
        if (( stat > __history_saved )); then
            update=1
        fi
    fi

    if (( update == 1 )); then
        # persist in-memory history items to the HISTFILE
        builtin history -a

        # clear the in-memory history list
        builtin history -c

        # re-read the HISTFILE into memory
        builtin history -r

        #__history_index=$1
        __history_index=${__history_prompt@P}
        __history_saved=$EPOCHSECONDS
    fi

    return "$ec"
}
