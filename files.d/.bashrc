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
        if [[ -f $p && -r $p ]]; then
            . "$p"
        fi
    done
}

_source_dir "$HOME/.bash"
