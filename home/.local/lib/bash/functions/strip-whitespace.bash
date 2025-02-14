strip-whitespace() {
    local -n ref=${1:?var name required}

    if [[ $ref =~ ^[[:space:]]+(.*) ]]; then
       ref=${BASH_REMATCH[1]}
    fi

    if [[ $ref =~ ^(.*[^[:space:]])[[:space:]]+$ ]]; then
       ref=${BASH_REMATCH[1]}
    fi
}
