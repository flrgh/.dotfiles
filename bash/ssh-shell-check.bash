if (( ${SSH:-0} == 1 && ${__RC_SSH_CHECKED:-0} == 0)); then
    if [[ -x $__RC_BASH && ! /proc/$$/exe -ef $__RC_BASH ]] \
        && $__RC_BASH -c 'echo 1' >/dev/null
    then
        export __RC_SSH_CHECKED=1

        # single command/ssh BatchMode (ssh <host> <command> <args>)
        if [[ $- = *c* || -n ${BASH_EXECUTION_STRING:-} ]]; then
            __RC_ARG0=${0:-'bash'}
            __RC_ARGS=(-c "$BASH_EXECUTION_STRING")

        # login (ssh <host>)
        else
            __RC_ARG0=${0:-'-bash'}
            __RC_ARGS=("$@")
        fi

        exec -a "$__RC_ARG0" "$__RC_BASH" "${__RC_ARGS[@]}"
        exit $?
    fi
fi
unset __RC_SSH_CHECKED SSH
