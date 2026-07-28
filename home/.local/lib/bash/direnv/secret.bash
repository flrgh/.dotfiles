secret::project() {
    log_error "called deprecated secret::project() function"

    local -r name=${1:?project name required}
    export BWS_PROJECT_NAME=$name
}

secret::inject() {
    if (( $# < 2 )); then
        log_error "usage: ${FUNCNAME[0]} <VAR> <SECRET>"
        return 1
    fi

    local var name value ref
    while (( $# > 0 )); do
        var=${1:?destination env var name required}
        name=${2:?secret name required}
        shift 2

        ref=$name
        if [[ $name =~ ^[^/]+$ ]]; then
            log_error "called secret::inject() with deprecated non-secret-ref input ($name)"
            ref="bws://${BWS_PROJECT_NAME:-main}/$name"
        fi

        value=$(secrets get --cache "$ref")

        export "${var}=${value}"
    done
}
