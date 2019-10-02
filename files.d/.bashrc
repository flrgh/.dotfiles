_log_rc() {
    local -r ctx=$1
    shift
    local stamp
    for msg in "$@"; do
        printf -v stamp '%s' '%(%F %T)T'
        printf "[%s] - (%s) - %s\n" "$stamp" "$ctx" "$msg"
    done
}

_debug_rc() {
    if [[ ${DEBUG_BASHRC} == 1 ]]; then
        local -r ctx="${BASH_SOURCE[2]}:${BASH_LINENO[1]} ${FUNCNAME[1]}"
        for msg in "$@"; do
            _log_rc "$ctx" "$msg"
        done
    fi
}

_source_dir() {
    local dir=$1
    [[ -d $dir ]] || return

    local opts
    opts=$(shopt -p nullglob dotglob)
    shopt -s nullglob dotglob globstar

    local p
    local files=("$dir"/**)
    eval "$opts"

    for p in "${files[@]}"; do
        if [[ -f $p || -h $p ]] && [[ -r $p ]]; then
            _debug_rc "sourcing file: $p"
            . "$p"
        fi
    done
}

_source_dir "$HOME/.bash"
