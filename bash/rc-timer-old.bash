declare -gi __RC_START=${EPOCHREALTIME/./}

__rc_timer_finish() {
    __RC_END=${EPOCHREALTIME/./}
    __RC_TIME_US=$(( __RC_END - __RC_START ))
    declare -g __RC_TIME=$(( __RC_TIME_US / 1000 )).$(( __RC_TIME_US % 1000 ))
}

timer() { :; }

__rc_timer_summary() { :; }
