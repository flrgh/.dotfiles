# shellcheck enable=deprecate-which

__rc_timer_finish
unset -f timer

if (( DEBUG_BASHRC > 0 )); then
    __rc_timer_summary
    __rc_debug "startup complete in ${__RC_TIME}ms"
else
    __rc_log \
        "bashrc" \
        "startup complete in ${__RC_TIME}ms"
fi

if (( __RC_LOG_FD > 0 )); then
    exec {__RC_LOG_FD}>&-
fi

# shellcheck disable=SC2046
{
    unset -n "${!__RC_@}" "${!__rc_@}"
    unset -v "${!__RC_@}" "${!__rc_@}"
    unset -f $(compgen -A function __rc_)

    # ${!<varname>*} doesn't expand associative array vars (?!)
    unset -n $(compgen -A variable __rc_) $(compgen -A variable __RC_)
    unset -v $(compgen -A variable __rc_) $(compgen -A variable __RC_)
}

if (( TRACE_BASHRC > 0 )); then
    set +x

    if (( BASH_XTRACEFD > 0 )); then
        exec {BASH_XTRACEFD}>&-
    fi

    unset BASH_XTRACEFD
fi

# luamake is annoying and tries to add a bash alias for itself every time it runs,
# so I need to leave this here so that it thinks the alias already exists *grumble*
#
# alias luamake=/home/michaelm/.config/nvim/tools/lua-language-server/3rd/luamake/luamake
