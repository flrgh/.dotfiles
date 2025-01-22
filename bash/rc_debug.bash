if (( DEBUG_BASHRC > 0 )); then
    __rc_debug() {
        local -r ctx="${BASH_SOURCE[2]}:${BASH_LINENO[1]} ${FUNCNAME[1]}"
        __rc_log_and_print "$ctx" "$@"
    }
else
    __rc_debug()    { :; }
    __rc_timer_start() { :; }
    __rc_timer_stop() { :; }
fi
