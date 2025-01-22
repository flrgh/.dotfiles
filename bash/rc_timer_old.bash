declare -A __RC_DURATION
declare -A __RC_DURATION_US
declare -A __RC_TIMER_START

declare -i __RC_TIMED_US_LAST=0
declare -i __RC_TIMED_US=0

declare -i __RC_TIMER_STACK_POS=0
declare -a __RC_TIMER_STACK=()

__rc_to_ms() {
    local -i value=$1
    printf -v REPLY '%s.%03d' \
        $(( value / 1000 )) \
        $(( value % 1000 ))
}

__rc_timer_push() {
    local -ri size=${#__RC_TIMER_STACK[@]}
    if (( size == 0 )); then
        __RC_TIMED_US_LAST=${EPOCHREALTIME/./}
    fi

    local -r key=$1

    __RC_TIMER_STACK+=("$key")
}

__rc_timer_pop() {
    local -nI dest=$1
    local -ri size=${#__RC_TIMER_STACK[@]}
    if (( size < 1 )); then
        __rc_debug "timer stack underflow"
        return 1
    fi

    # shellcheck disable=SC2034
    dest=${__RC_TIMER_STACK[-1]}
    unset "__RC_TIMER_STACK[-1]"

    if (( size == 1 )); then
        local -ri now=${EPOCHREALTIME/./}
        local -ri duration=$(( now - __RC_TIMED_US_LAST ))
        __RC_TIMED_US+=$duration
    fi
}

__rc_timer_start() {
    local -r key=$1
    local -ri now=${EPOCHREALTIME/./}

    __rc_timer_push "$key"
    __RC_TIMER_START[$key]=$now
}

__rc_timer_stop() {
    local -ri now=${EPOCHREALTIME/./}

    local key
    __rc_timer_pop key || return

    local -ri start=${__RC_TIMER_START[$key]:-0}

    if (( start == 0 )); then
        return
    fi

    local -ri duration=$(( now - start ))
    local -ri last=${__RC_DURATION_US[$key]:-0}
    local -ri total=$(( duration + last ))
    __RC_DURATION_US[$key]=$total

    # reformat from us to ms for display
    __rc_to_ms "$total"
    __RC_DURATION[$key]=${REPLY}ms
}

__rc_timer_summary() {
    if (( ${#__RC_TIMER_STACK[@]} > 0 )); then
        __rc_warn "timer strack should be empty, but: ${__RC_TIMER_STACK[*]}"
    fi

    {
        for __rc_key in "${!__RC_DURATION[@]}"; do
            __rc_time=${__RC_DURATION[$__rc_key]}
            __rc_to_ms "$__rc_time"
            local ms=$REPLY
            printf '%-16s %s\n' "${ms}ms" "$__rc_key"
        done
    } \
        | sort -n -k1 \
        | while read -r line; do
            __rc_debug "$line"
        done

    __rc_untimed_us=$(( __RC_TIME_US - __RC_TIMED_US ))
    if (( __rc_untimed_us > 0 )); then
        __rc_to_ms "$__RC_TIMED_US"
        __rc_timed=$REPLY

        __rc_to_ms "$__rc_untimed_us"
        __rc_untimed=$REPLY

        __rc_debug "accounted time: ${__rc_timed}ms"
        __rc_debug "unaccounted time: ${__rc_untimed}ms"
    fi
}
