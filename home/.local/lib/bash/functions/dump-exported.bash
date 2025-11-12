dump-exported() {
    local -a vars
    compgen -V vars -e

    local var
    for var in "${vars[@]}"; do
        dump-var "$var"
    done
}
