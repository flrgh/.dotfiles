_CLEANUP=()

_add_cleanup() {
    for exp in "$@"; do
        _CLEANUP+=("$exp")
    done
}

_cleanup_var() {
    for var in "$@"; do
        _add_cleanup "unset $var"
    done
}

_cleanup_func() {
    for f in "$@"; do
        _add_cleanup "unset -f $f"
    done
}

_cleanup_func _cleanup_func _add_cleanup _cleanup_var

_stamp() {
    date "+%s.%3N"
}

_cleanup_func _stamp

_log_rc() {
    local -r ctx=$1
    shift
    local stamp
    for msg in "$@"; do
        stamp=$(date "+%F %T.%3N")
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

_cleanup_func _source_dir

_RC_START=$(_stamp)

_source_dir "$HOME/.bash"

_RC_END=$(_stamp)

_time=0

if iHave bc; then
    _time=$(bc <<< "$_RC_END - $_RC_START")

elif iHave python; then
    _time=$(python \
        -c 'import sys; sys.stdout.write(str(round(float(sys.argv[1]) - float(sys.argv[2]), 3)))' \
        "$_RC_END" "$_RC_START"
    )
fi

printf -v  _time '%.3f' "$_time"
_debug_rc ".bashrc sourced in $_time seconds"

for stmt in "${_CLEANUP[@]}"; do
    _debug_rc "CLEANUP: $stmt"
    eval "$stmt"
done

unset -f _debug_rc _log_rc
unset _RC_START _RC_END _time

# luamake is annoying and tries to add a bash alias for itself every time it runs,
# so I need to leave this here so that it thinks the alias already exists *grumble*
#
# alias luamake=/home/michaelm/.config/nvim/tools/lua-language-server/3rd/luamake/luamake
