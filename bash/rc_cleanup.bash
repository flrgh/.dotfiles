# shellcheck enable=deprecate-which

if (( ${#__RC_TIMER_STACK[@]} > 0 )); then
    __rc_warn "timer strack should be empty, but: ${__RC_TIMER_STACK[*]}"
fi

__RC_END=${EPOCHREALTIME/./}
__RC_TIME_US=$(( __RC_END - __RC_START ))
__RC_TIME=$(( __RC_TIME_US / 1000 )).$(( __RC_TIME_US % 1000 ))

if (( DEBUG_BASHRC > 0 )); then
    {
        for __rc_key in "${!__RC_DURATION[@]}"; do
            __rc_time=${__RC_DURATION[$__rc_key]}
            printf '%-16s %s\n' "$__rc_time" "$__rc_key"
        done
    } \
        | sort -n -k1 \
        | while read -r line; do
            __rc_debug "$line"
        done

    __rc_untimed_us=$(( __RC_TIME_US - __RC_TIMED_US ))
    if (( __rc_untimed_us > 0 )); then
        __rc_timed=$(( __RC_TIMED_US / 1000 )).$(( __RC_TIMED_US % 1000 ))
        __rc_untimed=$(( __rc_untimed_us / 1000 )).$(( __rc_untimed_us % 1000 ))
        __rc_debug "accounted time: ${__rc_timed}ms"
        __rc_debug "unaccounted time: ${__rc_untimed}ms"
    fi

    __rc_debug "startup complete in ${__RC_TIME}ms"
else
    __rc_log \
        "bashrc" \
        "startup complete in ${__RC_TIME}ms"
fi

if (( TRACE_BASHRC > 0 )); then
    set +x

    if (( BASH_XTRACEFD > 0 )); then
        exec {BASH_XTRACEFD}>&-
    fi

    unset BASH_XTRACEFD
fi

if (( __RC_LOG_FD > 0 )); then
    exec {__RC_LOG_FD}>&-
fi

# shellcheck disable=SC2046
unset -v "${!__RC_@}" "${!__rc_@}"
# shellcheck disable=SC2046
unset -f $(compgen -A function __rc_)

# apparently ${!<varname>*} doesn't expand associative array vars (?!),
# so we'll unset these manually
unset -v __RC_DURATION
unset -v __RC_DURATION_US
unset -v __RC_TIMER_START

# luamake is annoying and tries to add a bash alias for itself every time it runs,
# so I need to leave this here so that it thinks the alias already exists *grumble*
#
# alias luamake=/home/michaelm/.config/nvim/tools/lua-language-server/3rd/luamake/luamake

# nvm is just as dumb as luamake
# export NVM_DIR="$HOME/.config/nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
