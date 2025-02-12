bin-path() {
    local -r name=${1?binary name is required}
    local path; path=$(builtin type -P "$name")

    if [[ -z $path ]]; then
        return 1
    fi

    command realpath "$path"
}
