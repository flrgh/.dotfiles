strip-whitespace() {
    local -n ref=${1:?var name required}

    local -i reset=0
    if ! shopt -q extglob; then
        shopt -s extglob
        reset=1
    fi

    ref=${ref##+([[:space:]])}
    ref=${ref%%+([[:space:]])}

    if (( reset == 1 )); then
        shopt -u extglob
    fi
}
