__RC_START=$(date "+%s.%3N")

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

iHave() {
    local -r cmd=$1
    if command -v "$cmd" &> /dev/null; then
        return 0
    fi
    return 1
}

if iHave bc; then
    _subtract() {
        local -r v=$(bc <<< "$1 - $2")
        printf '%.3f' "$v"
    }
elif iHave python; then
    _subtract() {
        python \
            -c 'import sys; sys.stdout.write(str(round(float(sys.argv[1]) - float(sys.argv[2]), 3)))' \
            "$1" "$2"
        }
else
    _subtract() {
        local l=$1
        local r=$2
        printf "%s" "$(( l - r ))"
    }
fi

_log_dir="$HOME/.local/var/log"
_log_file="$_log_dir/bashrc.log"

_log_rc() {
    local -r ctx=$1
    shift
    local stamp
    for msg in "$@"; do
        stamp=$(date "+%F %T.%3N")
        printf "[%s] - (%s) - %s\n" "$stamp" "$ctx" "$msg"
    done
}

declare -A __times
_cleanup_var __times


DEBUG_BASHRC=${DEBUG_BASHRC:-0}

if (( DEBUG_BASHRC > 0 )); then
    mkdir -p "$_log_dir"

    _debug_rc() {
        if [[ ${DEBUG_BASHRC} == 1 ]]; then
            local -r ctx="${BASH_SOURCE[2]}:${BASH_LINENO[1]} ${FUNCNAME[1]}"
            for msg in "$@"; do
                _log_rc "$ctx" "$msg" | tee -a "$_log_file"
            done
        fi
    }

    _timer_start() {
        local -r key=$1
        __times[$key]=$(_stamp)
    }

    _timer_stop() {
        local -r key=$1
        local -r start=${__times[$key]}
        local -r now=$(_stamp)
        __times[$key]=$(_subtract "$now" "$start")
    }

    _cleanup_var __time_started
else
    _debug_rc()    { :; }
    _timer_start() { :; }
    _timer_stop() { :; }
fi

_cleanup_func _timer_start _timer_stop

_source_file() {
    local -r fname=$1
    local ret
    if [[ -f $fname || -h $fname ]] && [[ -r $fname ]]; then
        _debug_rc "sourcing file: $fname"
        local -r key="_source_file($fname)"
        _timer_start "$key"

        # shellcheck disable=SC1090
        source "$fname"
        ret=$?

        _timer_stop "$key"
        _debug_rc "sourced file $fname in ${__times[$key]}"
    else
        _debug_rc "$fname does not exist or is not a regular file"
        ret=1
    fi

    return $ret
}

_source_dir() {
    local dir=$1
    if ! [[ -d $dir ]]; then
        _debug_rc "$dir does not exist"
        return
    fi

    local -r key="_source_dir($dir)"
    _timer_start "$key"

    local files=("$dir"/*)

    for p in "${files[@]}"; do
        _source_file "$p"
    done

    _timer_stop "$key"

    _debug_rc "sourced dir $dir in ${__times[$key]}"
}

_cleanup_func _source_dir

_source_dir "$HOME/.local/bash/rc.d"

for (( idx=${#_CLEANUP[@]}-1 ; idx>=0 ; idx-- )) ; do
    stmt=${_CLEANUP[$idx]}
    _debug_rc "CLEANUP: $stmt"
    eval "$stmt"
done

__RC_END=$(date "+%s.%3N")
if [[ -d $_log_dir ]]; then
    _log_rc \
        "bashrc" \
        "startup complete in $(_subtract "$__RC_END" "$__RC_START")" \
    >> "$_log_file"
fi

unset -f _debug_rc _subtract _log_rc
unset _CLEANUP __RC_START __RC_END _log_dir _log_dir

# luamake is annoying and tries to add a bash alias for itself every time it runs,
# so I need to leave this here so that it thinks the alias already exists *grumble*
#
# alias luamake=/home/michaelm/.config/nvim/tools/lua-language-server/3rd/luamake/luamake
