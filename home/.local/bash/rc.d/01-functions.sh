# This is for functions that will be available to the shell after
# .bashrc is sourced
#
# Functions used only while sourcing .bashrc should go in .bashrc

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

strip-whitespace() {
    local -r name=${1?var name required}
    local -n ref=$1

    local before=${!name}
    local after=$before

    while true; do
        after=${after##[[:space:]]}
        after=${after%%[[:space:]]}

        if [[ $after == "$before" ]]; then
            break
        fi

        before=$after
    done

    ref=$after
}

is-array() {
    local -r name=$1
    local -rn ref=$1

    local -r dec=${ref@A}

    local -r pat="declare -(a|A)"

    [[ $dec =~ $pat ]]
}

dump-array() {
    local -r name=$1
    local -rn ref=$1

    local i
    for i in "${!ref[@]}"; do
        printf '%-32s => %q\n' \
                "${name}[$i]" \
                "${ref[$i]}"
    done
}

complete -A arrayvar dump-array

unset -v __PATH_VARS
declare -g -A __PATH_VARS=()
__PATH_VARS[PATH]=':'
__PATH_VARS[CDPATH]=':'
__PATH_VARS[MANPATH]=':'
__PATH_VARS[LUA_PATH]=';'
__PATH_VARS[LUA_CPATH]=';'
__PATH_VARS[MODULEPATH]=':'
__PATH_VARS[BASH_LOADABLES_PATH]=':'
__PATH_VARS[XDG_DATA_DIRS]=':'

is-path-var() {
    local -r var=${1?var name is required}

    test -n "${__PATH_VARS[$var]:-}"
}

is-set() {
    local -r var=${1?var name is required}

    declare -p "$var" &>/dev/null
}

dump-path-var() {
    local -r name=$1

    if [[ -z ${name:-} ]]; then
        for var in "${!__PATH_VARS[@]}"; do
            if is-set "$var"; then
                dump-path-var "$var"
            fi
        done

        return
    fi

    local -r default=':'
    local sep=${__PATH_VARS[$name]:-"${default}"}

    local -a arr
    mapfile -t -d "$sep" arr <<< "${!name}"

    local -i offset=0

    local part
    for part in "${arr[@]}"; do
        strip-whitespace part

        printf '%-32s => %s\n' \
            "${name}[$(( offset++ ))]" \
            "$part"
    done
}

complete -W "${!__PATH_VARS[*]}" dump-path-var

dump-var() {
    local -r name=$1
    if [[ -z $name ]]; then
        for v in $(compgen -v); do
            dump-var "$v"
        done
        return
    fi

    if ! is-set "$name"; then
        echo "$name is unset"

    elif is-array "$name"; then
        echo "$name is an array"
        dump-array "$name"

    elif is-path-var "$name"; then
        echo "$name is PATH or a PATH-like env var"
        dump-path-var "$name"

    else
        local -rn value=$name
        printf "%-32s => %q\n" \
            "$name" \
            "${value}"
    fi
}

complete -A variable dump-var
