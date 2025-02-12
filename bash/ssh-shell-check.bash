: "${SSH:=0}"
: "${__RC_SSH_CHECK:=0}"

if ((SSH == 1 && __RC_SSH_CHECK == 0)); then
    __RC_BASH=$HOME/.local/bin/bash
    if [[ -x $__RC_BASH && ! /proc/$$/exe -ef $__RC_BASH ]]; then
        export __RC_SSH_CHECK=1
        exec -a "${0:-'-bash'}" "$__RC_BASH" "$@"
        exit $?
    fi
fi
unset __RC_SSH_CHECK
