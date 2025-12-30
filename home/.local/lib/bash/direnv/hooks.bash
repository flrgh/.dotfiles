hooks::add() {
    local exp
    printf -v exp "$@"

    if [[ ! -v BASH_DIRENV_HOOKS ]]; then
        declare -g -x BASH_DIRENV_HOOKS
    fi

    BASH_DIRENV_HOOKS="${BASH_DIRENV_HOOKS:+"${BASH_DIRENV_HOOKS};"}${exp}"
}

hooks::source() {
    local -r fname=${1:?filename required}
    watch::file "$fname"
    hooks::add "source %q" "$fname"
}
