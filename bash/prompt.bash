__prompt_reset=${__prompt_reset:-""}
__prompt_alert=${__prompt_alert:-""}

__ps1_stale=${__ps1_stale:-'(!)'}

__ps1_default_prefix=${__ps1_default_prefix:-"@\h \w"}
__ps1_default_middle=" "
__ps1_default_suffix='\$ '

__ps1_default="${__ps1_default_prefix}${__ps1_default_middle}${__ps1_default_suffix}"

__ps1_prefix=$__ps1_default_prefix
__ps1_middle=$__ps1_default_middle
__ps1_suffix=$__ps1_default_suffix
__ps1=""

__ps1_rebuild() {
    __ps1="${__ps1_prefix}${__ps1_middle}${__ps1_suffix}"
    PS1="$__ps1"
}

__ps1_set_middle() {
    __ps1_middle=${1:-${__ps1_default_middle}}
    __ps1_rebuild
}

__ps1_set_prefix() {
    __ps1_prefix=${1:-${__ps1_default_prefix}}
    __ps1_rebuild
}

__ps1_set_suffix() {
    __ps1_suffix=${1:-${__ps1_default_suffix}}
    __ps1_rebuild
}


if (( DEBUG_BASHRC > 0 )); then
    __ps1_set_suffix '(# \#) (! \!) \$ '
else
    __ps1_rebuild
fi


__prompt_cmd="\#"
declare -gi __need_prompt_reset=0
declare -gi __last_cmd_number=0


# update PS1 when a command returns a non-zero exit code
__last_status() {
    local -i ec=$1

    # we check the command counter so that we can only consider the exit code
    # from "new" commands and reset the state otherwise
    #
    # this way, pressing <enter> has the effect of clearing the prompt from the
    # last non-zero status
    local -i counter=${__prompt_cmd@P}
    local -i last_cmd=$__last_cmd_number
    __last_cmd_number=$counter

    if (( counter > last_cmd && ec != 0 )); then
        # uh oh red alert!!!!
        __need_prompt_reset=1
        __ps1_set_middle " (${__prompt_alert}${ec}${__prompt_reset}) "

    elif (( __need_prompt_reset == 1 )); then
        __need_prompt_reset=0
        __ps1_set_middle
    fi
}


declare -gi __history_index=0
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

__read_history() {
    builtin history -r
    __history_index=${__history_prompt@P}
}

__save_history() {
    if (( __history_saving_enabled == 0 )); then
        return
    fi

    # -a => persist in-memory history items to the HISTFILE
    # -c => clear the in-memory history list
    builtin history -a
    builtin history -c
    sync "$HISTFILE"
}

__reload_history() {
    __save_history
    __read_history
}

__check_history() {
    # re-load
    if (( __history_index == 0 )); then
        __read_history
        return 0
    fi

    local -ri idx=${__history_prompt@P}

    # we executed a new command: update the histfile
    if (( idx > __history_index )); then
        __reload_history
        events_publish "$EVENT_ID_HISTORY"
    fi
}

declare -gi __hash_loaded_at=0
__hash_loaded=""
if [[ -s ${__hash_file:?} ]]; then
    __hash_loaded=$(< "${__hash_file:?}")
    __hash_loaded_at=$(( ${EPOCHREALTIME/.} / 1000 )) # convert us to ms
fi

declare -gi __is_stale=0

replace() {
    local bash; bash=$(realpath "/proc/$$/exe")

    __teardown

    if [[ ! -x $bash ]]; then
        bash=${bash%" (deleted)"}
    fi

    if [[ ! -x $bash ]]; then
        bash=/usr/bin/bash
    fi

    if [[ -v TMUX && -v TMUX_PANE ]]; then
        exec tmux respawn-pane \
            -k \
            -e __RC_REPLACED="$$" \
            -c "$PWD" \
            "$bash" \
            "$@"
    else
        __RC_REPLACED="$$" exec \
            -a "${0:-${bash}}" \
            "$bash" \
            "$@"
    fi
}

__rehash() {
    local rcfile=${__hash_rcfile:-"$HOME/.bashrc"}
    local sum; sum=$(md5sum "$rcfile")
    sum=${sum%% *}
    printf '%s\n' "$sum" > "$__hash_file"
    touch --reference "$rcfile" "$__hash_file"
    __hash_loaded=${sum}
    __hash_loaded_at=$(( ${EPOCHREALTIME/.} / 1000 )) # convert us to ms
}

__check_stale_exe() {
    [[ ! /proc/$$/exe -ef ${__EXE:?} ]]
}

__check_stale_hash() {
    if [[ -z $__hash_loaded || $__hash_loaded_at -eq 0 ]]; then
        __rehash
        return 1
    fi

    __get_mtime "$__hash_file"
    local -i hash_mtime=$(( REPLY * 1000)) # convert s to ms

    if (( hash_mtime > __hash_loaded_at )); then
        if [[ $(< "$__hash_file") == "$__hash_loaded" ]]; then
            # the hash file was updated but didn't change
            # kinda weird but okay
            __hash_loaded_at=$hash_mtime
        else
            return 0
        fi
    fi
    return 1
}

__set_stale() {
    if (( __is_stale )); then
        return
    fi
    __is_stale=1
    __ps1_set_prefix "${__ps1_stale} ${__ps1_default_prefix}"

    # no use listening for more of these events
    events_on "$EVENT_ID_CONF"
}

__check_stale() {
    if (( __is_stale )); then
        return
    fi

    if __check_stale_hash; then
        echo "WARN: ~/.bashrc has changed since loading" >&2
        echo "WARN: replace this session by calling 'replace'" >&2
        __set_stale
    fi

    if __check_stale_exe; then
        echo "WARN: $__EXE has changed since loading" >&2
        echo "WARN: replace this session by calling 'replace'" >&2
        __set_stale
    fi
}

__teardown() {
    trap -- "" EXIT
    events_teardown || true
    __save_history || true
}

events_init
events_on "$EVENT_ID_CONF" __check_stale
events_on "$EVENT_ID_HISTORY" __reload_history

builtin trap __teardown EXIT
