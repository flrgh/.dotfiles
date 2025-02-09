declare -i DEBUG_BASHRC=${DEBUG_BASHRC:-0}
declare -i TRACE_BASHRC=${TRACE_BASHRC:-0}

declare __RC_TRACE_FILE
if (( TRACE_BASHRC > 0 )); then
    __RC_TRACE_FILE=${__RC_LOG_DIR}/bashrc.trace.$$.log
    __rc_print "tracing" "Trace logfile: $__RC_TRACE_FILE"
    exec {BASH_XTRACEFD}>"$__RC_TRACE_FILE"
    set -x
fi

if (( DEBUG_BASHRC > 0 )); then
    __rc_debug() {
        local -r ctx="${BASH_SOURCE[2]}:${BASH_LINENO[1]} ${FUNCNAME[1]}"
        __rc_log_and_print "$ctx" "$@"
    }
else
    __rc_debug() { :; }
fi
