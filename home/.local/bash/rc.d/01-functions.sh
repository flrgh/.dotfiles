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
        declare -g -x "$var"="$p"
    elif ! [[ $current =~ "${sep}"?"$p""${sep}"? ]]; then
        _debug_rc "Prepending $p to \$${var}"
        local new=${p}${sep}${current}
        declare -g -x "$var"="$new"
    else
        _debug_rc "\$${var} already contains $p"
    fi
}

_cleanup_func addPath

iHave() {
    local -r cmd=$1
    command -v "$cmd" &> /dev/null
}

_cleanup_func iHave

isFunction() {
    [[ $(type -t "$1") = function ]]
}

_cleanup_func isFunction

isExe() {
    [[ -n $(type -f -p "$1") ]]
}

_cleanup_func isExe

extract() {
    if [[ -z $1 ]]; then
        echo "usage: extract <filename>"
        return 1
    fi

    if ! test -f "$1"; then
        echo "'$1' is not a valid file"
        return 1
    fi

    case $1 in
        *.tar.bz2)   tar xjf "$1"     ;;
        *.tar.gz)    tar xzf "$1"     ;;
        *.tar.xz)    tar xf "$1"      ;;
        *.bz2)       bunzip2 "$1"     ;;
        *.rar)       rar x "$1"       ;;
        *.gz)        gunzip "$1"      ;;
        *.tar)       tar xf "$1"      ;;
        *.tbz2)      tar xjf "$1"     ;;
        *.tgz)       tar xzf "$1"     ;;
        *.zip)       unzip "$1"       ;;
        *.Z)         uncompress "$1"  ;;
        *.7z)        7z x "$1"        ;;
        *)           echo "'$1' cannot be extracted via extract()"
                     return 1
                     ;;
    esac
}

dump-array() {
    local -r name=$1
    local -rn ref=$1

    for i in "${!ref[@]}"; do
        local fq="${name}[$i]"

    printf "%-32s => %q\n" \
            "$fq" \
            "${ref[$i]}"
    done
}

complete -A arrayvar dump-array

dump-var() {
    local -r name=$1
    if [[ -z $name ]]; then
        for v in $(compgen -v); do
            dump-var "$v"
        done
        return
    fi

    local -rn ref=$1

    local -r dec=${ref@A}

    local -r pat="declare -(a|A)"

    if [[ $dec =~ $pat ]]; then
        dump-array "$name"
        return
    fi

    printf "%-32s => %q\n" \
        "$name" \
        "$ref"
}

complete -A variable dump-var
