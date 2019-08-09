_source_dir() {
    local dir=$1
    [[ -d $dir ]] || return

    local opts
    opts=$(shopt -p nullglob dotglob)
    shopt -s nullglob dotglob

    local p
    for p in "$dir"/*; do
        if [[ -f $p && -r $p ]]; then
            . "$p"
        elif [[ -d $p && -r $p ]]; then
            _source_dir "$p"
        fi
    done
    eval "$opts"
}

_source_dir "$HOME/.bash"
