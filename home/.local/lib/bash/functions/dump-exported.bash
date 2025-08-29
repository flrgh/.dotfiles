if (( BASH_USER_MODERN == 1 )); then
    dump-exported() {
        local v
        # shellcheck disable=SC2043
        for v in ${ compgen -e;}; do
            dump-var "$v"
        done
    }
else
    dump-exported() {
        local v
        for v in $(compgen -e); do
            dump-var "$v"
        done
    }
fi
