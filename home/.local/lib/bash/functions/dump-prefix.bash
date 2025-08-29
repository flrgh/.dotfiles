if (( BASH_USER_MODERN == 1 )); then
    dump-prefix() {
        local arg v
        for arg in "$@"; do
            # shellcheck disable=SC2043
            for v in ${ compgen -v "$arg";}; do
                dump-var "$v"
            done
        done
    }
else
    dump-prefix() {
        local arg v
        for arg in "$@"; do
            for v in $(compgen -v "$arg"); do
                dump-var "$v"
            done
        done
    }
fi
