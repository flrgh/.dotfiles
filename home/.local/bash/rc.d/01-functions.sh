# This is for functions that will be available to the shell after
# .bashrc is sourced
#
# Functions used only while sourcing .bashrc should go in .bashrc

__rc_source_file "$BASH_USER_LIB"/var.bash
__rc_source_file "$BASH_USER_LIB"/array.bash

:q() {
    echo "hey you're not in vim anymore, but I can exit the shell for you..."
    sleep 0.75 && exit
}

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
    local -n ref=${1:?var name required}

    if shopt -q -p extglob; then
        ref=${ref##+([[:space:]])}
        ref=${ref%%+([[:space:]])}
        return
    fi

    local before=$ref

    while true; do
        ref=${ref##[[:space:]]}
        ref=${ref%%[[:space:]]}

        if [[ $ref == "$before" ]]; then
            break
        fi

        before=$ref
    done
}

dump-array() {
    local -r name=$1
    local -rn ref=$1

    local i
    local -i width=32
    local key len

    for i in "${!ref[@]}"; do
        key="${name}[$i]"
        len=${#key}
        width=$(( len > width ? len : width ))
    done

    local fmt="%-${width}s => %s\n"
    for i in "${!ref[@]}"; do
        printf "$fmt" \
                "${name}[$i]" \
                "${ref[$i]}"
    done
}

complete -A arrayvar dump-array

unset -v __DELIMITED_VARS
declare -g -A __DELIMITED_VARS=(
    [BASHOPTS]=':'
    [BASH_LOADABLES_PATH]=':'
    [CDPATH]=':'
    [FIGNORE]=':'
    [EXECIGNORE]=':'
    [GLOBIGNORE]=':'
    [HISTCONTROL]=':'
    [HISTIGNORE]=':'
    [LUA_CPATH]=';'
    [LUA_PATH]=';'
    [MAILPATH]=':'
    [MANPATH]=':'
    [MODULEPATH]=':'
    [PATH]=':'
    [SHELLOPTS]=':'
    [XDG_DATA_DIRS]=':'
)

__is_delimited_string() {
    local -r var=${1?var name is required}

    test -n "${__DELIMITED_VARS[$var]:-}"
}

is-set() {
    local -r var=${1?var name is required}

    declare -p "$var" &>/dev/null
}

__dump_delimited_var() {
    local -r name=$1

    if [[ -z ${name:-} ]]; then
        for var in "${!__DELIMITED_VARS[@]}"; do
            if is-set "$var"; then
                __dump_delimited_var "$var"
            fi
        done

        return
    fi

    local -r default=':'
    local sep=${__DELIMITED_VARS[$name]:-"${default}"}

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

__print_attributes() {
    local -r name=$1

    local -a attrs=()

    if (( VAR_INFO["is_array"] )); then
        attrs+=("array")
    fi

    if (( VAR_INFO["is_assoc_array"] )); then
        attrs+=("associative-array")
    fi

    if (( VAR_INFO["is_integer"] )); then
        attrs+=("integer")
    fi

    if (( VAR_INFO["is_nameref"] )); then
        attrs+=("nameref")
    fi

    if (( VAR_INFO["is_exported"] )); then
        attrs+=("exported")
    fi

    if (( VAR_INFO["is_readonly"] )); then
        attrs+=("read-only")
    fi

    if (( VAR_INFO["is_lowercase"] )); then
        attrs+=("lower-case")
    fi

    if (( VAR_INFO["is_uppercase"] )); then
        attrs+=("upper-case")
    fi

    if (( VAR_INFO["is_trace"] )); then
        attrs+=("trace")
    fi

    if (( ${#attrs[@]} > 0 )); then
        local attrs
        array-join-var attrs ', ' "${attrs[@]}"
        printf '%-32s => %s\n' \
            "$name (attributes)" \
            "$attrs"
    fi
}

__print_nameref_target() {
    printf '%s' "$1"

    if ! __parse_decl "$1"; then
        printf '\n'
        return 0
    fi

    if [[ $VAR_FLAGS != *n* ]]; then
        printf '\n'
        return 0
    fi

    if [[ -z "${VAR_VALUE:-}" ]]; then
        printf '\n'
        return 0
    fi

    printf ' -> '
    __print_nameref_target "$VAR_VALUE"
}

dump-var() {
    local -r nargs=$#
    if (( nargs == 0 )); then
        for v in $(compgen -v); do
            dump-var "$v"
        done
        return
    elif (( nargs > 1 )); then
        local -i c=0

        for v in "$@"; do
            if (( c++ > 0 )); then
                printf -- '---\n'
            fi

            dump-var "$v"
        done
        return
    fi

    local -r name=$1
    if ! var-info "$name"; then
        if (( VAR_INFO["is_valid"] )); then
            printf '%s is undeclared\n' "$name"
            return
        fi

        printf '"%s" is not a valid identifier\n' "$name"
        return
    fi

    if (( ! VAR_INFO["is_set"] )); then
        printf '%s is unset\n' "$name"
        __print_attributes "$name"
        return
    fi

    __print_attributes "$name"

    if (( VAR_INFO["is_array"] )); then
        printf '%-32s\n' "$name items:"
        dump-array "$name"

    elif (( VAR_INFO["is_assoc_array"] )); then
        printf '%-32s\n' "$name items:"
        dump-array "$name"

    elif __is_delimited_string "$name"; then
        local delim=${__DELIMITED_VARS[$name]}
        printf '%-32s => "%s"\n' \
            "$name (delim)" \
            "$delim"
        __dump_delimited_var "$name"

    elif (( VAR_INFO["is_nameref"] )); then
        __print_nameref_target "$name"
        printf '\n'
        dump-var "${VAR_INFO["nameref_target"]}"
        return

    else
        local -rn value=$name
        printf "%-32s => %q\n" \
            "${name} (value)" \
            "${value}"
    fi
}

complete -A variable dump-var

dump-prefix() {
    for arg in "$@"; do
        for v in $(compgen -v "$arg"); do
            dump-var "$v"
        done
    done
}

dump-exported() {
    for v in $(compgen -e); do
        dump-var "$v"
    done
}


complete -A variable dump-prefix

dump-matching() {
    local -r pat=${1?pattern or substring required}

    for var in $(compgen -v); do
        if [[ $var = *${pat}* ]]; then
            dump-var "$var"
        fi
    done
}

bin-path() {
    local -r name=${1?binary name is required}
    local path; path=$(builtin type -P "$name")

    if [[ -z $path ]]; then
        return 1
    fi

    realpath "$path"
}
