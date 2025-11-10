dump-prefix() {
    if (( $# == 0 )); then
        echo "pattern or substring required" >&2
        return 1
    fi

    local -a vars
    compgen -V vars -v

    local pre var
    for var in "${vars[@]}"; do
        for pre in "$@"; do
            if [[ $var = ${pre}* ]]; then
                dump-var "$var"
                break
            fi
        done
    done
}
