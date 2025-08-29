if (( BASH_USER_MODERN == 1 )); then
    dump-matching() {
        local -r pat=${1?pattern or substring required}

        local var
        # shellcheck disable=SC2043
        for var in ${ compgen -v;}; do
            if [[ $var = *${pat}* ]]; then
                dump-var "$var"
            fi
        done
    }
else
    dump-matching() {
        local -r pat=${1?pattern or substring required}

        local var
        for var in $(compgen -v); do
            if [[ $var = *${pat}* ]]; then
                dump-var "$var"
            fi
        done
    }
fi
