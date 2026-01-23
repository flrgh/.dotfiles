BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}
source "$BASH_USER_LIB"/__init.bash
(( BASH_USER_LIB_SOURCED[events]++ == 0 )) || return 0

declare -g __pid_dir=${XDG_RUNTIME_DIR:?}/bash-pids
declare -g __pid_file="${__pid_dir}/$$"

declare -g EVENT_ID_CONF=SIGUSR1
declare -g EVENT_ID_HISTORY=SIGUSR2

declare -g -A __event_callbacks=()
declare -g -A __event_triggers=()
declare -gi __events_shutdown=0

__set_event_conf() {
    __event_conf=1
}

__set_event_history() {
    __event_history=1
}

if builtin enable rm &>/dev/null; then
    builtin enable -n rm
    __events_rm() {
        builtin rm "$@"
    }
else
    __events_rm() {
        command rm "$@"
    }
fi

if builtin enable realpath &>/dev/null; then
    builtin enable -n realpath
    __events_is_bash() {
        local -r subject=${1:?}
        local exe
        builtin realpath -a exe -q "$subject" &>/dev/null \
            && [[ ${exe[0]} == */bin/bash* ]]
    }
else
    __events_is_bash() {
        local -r subject=${1:?}
        local path
        path=$(realpath -m "$subject" 2>/dev/null) \
            && [[ $path = */bin/bash* ]]
    }
fi


events_init() {
    [[ -d $__pid_dir ]] || mkdir -p "$__pid_dir"
    : >"$__pid_file"
    builtin trap -- "" "$EVENT_ID_CONF"
    builtin trap -- "" "$EVENT_ID_HISTORY"
}

events_on() {
    local -r evt=${1:?}
    local -r cb=${2:-}

    if [[ $evt != "$EVENT_ID_CONF" && $evt != "$EVENT_ID_HISTORY" ]]; then
        echo "ERROR: invalid event id: $evt"
        return 1
    fi

    if [[ -z ${cb:-} ]]; then
        __event_callbacks[$evt]=""
        __event_triggers[$evt]=0
        builtin trap -- "" "$evt"
        return 0
    fi

    if ! declare -F "$cb" &>/dev/null; then
        echo "ERROR: invalid callback"
        events_on "$evt"
        return 1
    fi
    __event_callbacks[$evt]="$cb"

    builtin trap -- "__event_triggers[$evt]=1" "$evt"
}

events_flush() {
    if (( __events_shutdown )); then
        return
    fi

    if [[ ! -e $__pid_file ]]; then
        : >"$__pid_file"

        # re-trigger event handlers if our pid file was missing
        __event_triggers[$EVENT_ID_CONF]=1
        __event_triggers[$EVENT_ID_HISTORY]=1
    fi

    if (( __event_triggers[$EVENT_ID_CONF] == 1 )); then
        __event_triggers[$EVENT_ID_CONF]=0
        if [[ -n ${__event_callbacks[$EVENT_ID_CONF]:-} ]]; then
            "${__event_callbacks[$EVENT_ID_CONF]}"
        fi
    fi

    if (( __event_triggers[$EVENT_ID_HISTORY] == 1 )); then
        __event_triggers[$EVENT_ID_HISTORY]=0
        if [[ -n ${__event_callbacks[$EVENT_ID_HISTORY]:-} ]]; then
            "${__event_callbacks[$EVENT_ID_HISTORY]}"
        fi
    fi
}

events_teardown() {
    if (( __events_shutdown )); then
        return
    fi

    __events_shutdown=1

    events_on "$EVENT_ID_CONF" || true
    events_on "$EVENT_ID_HISTORY" || true
    __events_rm -f "$__pid_file" || true
}

events_publish() {
    local -r evt=${1:?}

    if [[ $evt != "$EVENT_ID_CONF" && $evt != "$EVENT_ID_HISTORY" ]]; then
        echo "ERROR: invalid event id: $evt"
        return 1
    fi

    local -a pids=()
    local file pid
    for file in "$__pid_dir"/*; do
        pid=${file##*/}

        if [[ $pid == "$$" ]]; then
            continue
        fi

        if [[ -O /proc/$pid ]] && __events_is_bash "/proc/$pid/exe"; then
            pids+=("$pid")
        else
            __events_rm -f "${file:?}"
        fi
    done

    if (( ${#pids[@]} > 0 )); then
        kill -s "$evt" "${pids[@]}"
    fi
}
