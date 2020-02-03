addPath() {
    local -r p=$1

    if [[ -z $p ]]; then
        _debug_rc "addPath called with empty value"
        return
    fi

    # default case is PATH, but some other styles (e.g. LUA_PATH) use different
    # separators like `;`
    local -r var=${2:-PATH}
    local -r sep=${3:-:}

    local -r current=${!var}

    _debug_rc "VAR: $var CURRENT: $current SEP: $sep NEW: $p"
    if [[ -z $current ]]; then
        _debug_rc "Setting \$${var} to $p"
        export "$var"="$p"
    elif ! [[ $current =~ "${sep}"?"$p""${sep}"? ]]; then
        _debug_rc "Prepending $p to \$${var}"
        local new=${p}${sep}${current}
        export "$var"="$new"
    else
        _debug_rc "\$${var} already contains $p"
    fi
}

iHave() {
    local -r cmd=$1
    if command -v "$cmd" &> /dev/null; then
        return 0
    fi
    return 1
}
