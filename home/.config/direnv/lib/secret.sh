__is_uuid() {
    [[ ${1:-} =~ ^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$ ]]
}

__get_bws_token() {
    if [[ -n ${BWS_ACCESS_TOKEN:-} ]]; then
        return
    fi

    local -r service=bws

    local token
    if ! token=$(secret-tool lookup service "$service"); then
        log_error "failed to get bws access token"
        return 1
    fi

    export BWS_ACCESS_TOKEN=${token:?token was empty}
}

__unset_bws_token() {
    unset BWS_ACCESS_TOKEN
}

secret::__check() {
    if ! has bws; then
        log_error "'bws' not found"
        return 1
    fi

    if ! has secret-tool; then
        log_error "'secret-tool' not found"
        return 1
    fi

    if ! has jq; then
        log_error "'jq' not found"
        return 1
    fi
}

__list_projects() {
    __get_bws_token

    log_status "fetching bws project list"

    local projects
    if ! projects=$(bws -o json project list); then
        __unset_bws_token
        log_error "failed retrieving bws project list"
        return 1
    fi
    __unset_bws_token

    printf '%s' "$projects"
}

__list_secrets() {
    __get_bws_token

    log_status "fetching bws secrets"

    local -a args=()
    if [[ -n ${BWS_PROJECT_ID:-} ]]; then
        args+=("$BWS_PROJECT_ID")
    fi

    local secrets
    if ! secrets=$(bws -o json secret list "${args[@]}"); then
        __unset_bws_token
        log_error "failed retrieving secrets"
        return 1
    fi
    __unset_bws_token

    printf '%s' "$secrets"
}

secret::project() {
    secret::__check
    local -r name=${1:?project name/id required}

    if __is_uuid "$name"; then
        unset BWS_PROJECT_NAME
        export BWS_PROJECT_ID=$name
        return

    elif [[ ${BWS_PROJECT_NAME:-} = "$name" && -n ${BWS_PROJECT_ID:-} ]]; then
        # already set
        return
    fi

    local projects; projects=$(__list_projects)
    local id
    id=$(jq \
        --raw-output \
        --arg name "$name" \
        '.[] | select(.name == $name) | .id' \
        <<< "$projects"
    )

    if [[ -z ${id:-} ]]; then
        log_error "bws project '$name' not found"
        return 1
    fi

    export BWS_PROJECT_ID=$id
    export BWS_PROJECT_NAME=$name
}

secret::inject() {
    secret::__check

    if (( $# < 2 )); then
        log_error "usage: ${FUNCNAME[0]} <VAR> <SECRET>"
        return 1
    fi

    local secrets; secrets=$(__list_secrets)

    local var name value
    while (( $# > 0 )); do
        var=${1:?destination env var name required}
        name=${2:?secret name required}
        shift 2

        value=$(jq \
            --raw-output \
            --arg key "$name" \
            '.[] | select(.key == $key or .id == $key) | .value' \
            <<< "$secrets"
        )

        export "${var}=${value}"
    done
}
