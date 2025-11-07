declare -g -A __WATCHED_FILES=()

watch::file() {
    local f
    for f in "$@"; do
        if [[ -z ${__WATCHED_FILES[$f]:-} ]]; then
            __WATCHED_FILES[$f]=1
            watch_file "$f"
        fi
    done
}

declare -g -A __WATCHED_DIRS=()

watch::dir() {
    local d
    for d in "$@"; do
        if [[ -z ${__WATCHED_DIRS[$d]:-} ]]; then
            __WATCHED_DIRS[$d]=1
            watch_dir "$d"
        fi
    done
}
