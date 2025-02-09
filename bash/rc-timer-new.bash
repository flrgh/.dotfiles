builtin timer reset
builtin timer start "bashrc"

__rc_to_ms() {
    local -i value=$1
    printf -v REPLY '%s.%03d' \
        $(( value / 1000 )) \
        $(( value % 1000 ))
}

__rc_timer_finish() {
    builtin timer stop
    __RC_TIME_US="${TIMERS[bashrc]}"
    __rc_to_ms "$__RC_TIME_US"
    declare -g __RC_TIME=$REPLY
}

if (( DEBUG_BASHRC > 0 )); then
    __rc_timer_summary() {
        local key line
        local value
        local -a lines=()

        for key in "${!TIMERS[@]}"; do
            if [[ $key == bashrc ]]; then
                continue
            fi
            __rc_to_ms "${TIMERS[$key]}"
            value=$REPLY
            printf -v line '%-16s %s\n' "${value}ms" "$key"
            lines+=("$line")
        done

        sort -n -k1 <<< "${lines[@]}" \
        | while read -r line; do
            __rc_log_and_print "timer" "$line"
        done

        local -i untimed=$(( __RC_TIME_US - TIMER_TOTAL ))
        if (( untimed > 0 )); then
            __rc_to_ms "$TIMER_TOTAL"
            __rc_timed=$REPLY
            __rc_to_ms "$untimed"
            __rc_untimed=$REPLY
            __rc_log_and_print "timer" "accounted time: ${__rc_timed}ms"
            __rc_log_and_print "timer" "unaccounted time: ${__rc_untimed}ms"
        fi
    }
else
    timer() { :; }
fi
