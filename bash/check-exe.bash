if [[ ! /proc/$$/exe -ef $__RC_LOCAL_BASH ]]; then
    SSH=${SSH:-0}
    __RC_SSH_CHECKED=${__RC_SSH_CHECKED:-0}

    if (( SSH == 1 && __RC_SSH_CHECKED == 0)) \
        && [[ -x $__RC_LOCAL_BASH  ]] \
        && $__EXE -c 'echo 1' >/dev/null
    then
        # single command/ssh BatchMode (ssh <host> <command> <args>)
        if [[ $- = *c* || -n ${BASH_EXECUTION_STRING:-} ]]; then
            __RC_ARG0=${0:-'bash'}
            __RC_ARGS=(-c "$BASH_EXECUTION_STRING")

        # login (ssh <host>)
        else
            __RC_ARG0=${0:-'-bash'}
            __RC_ARGS=("$@")
        fi

        __RC_SSH_CHECKED=1 exec -a "$__RC_ARG0" "$__EXE" "${__RC_ARGS[@]}"
        exit $?
    fi

    _BASH=$(realpath -m "/proc/$$/exe")
    echo "WARN: /proc/\$\$/exe is $_BASH and not $__RC_LOCAL_BASH" >&2
    echo "WARN: exiting from ~/.bashrc" >&2
    return
fi
unset __RC_SSH_CHECKED SSH _BASH
