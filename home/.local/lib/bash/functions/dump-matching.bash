dump-matching() {
    if (( $# == 0 )); then
        echo "pattern or substring required" >&2
        return 1
    fi

    local -a vars
    compgen -V vars -v

    local pat var
    for var in "${vars[@]}"; do
        for pat in "$@"; do
            if [[ $var = *${pat}* ]]; then
                dump-var "$var"
                break
            fi
        done
    done
}
