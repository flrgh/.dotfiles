BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}

source "$BASH_USER_LIB"/var.bash
source "$BASH_USER_LIB"/array.bash

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

if enable dsv &>/dev/null; then
    __split() {
        dsv -a ARR -d "$1" "$2"
    }
else
    __split() {
        mapfile -t -d "$1" ARR <<< "$2"
    }
fi

__dump_delimited_var() {
    local -r name=$1

    if [[ -z ${name:-} ]]; then
        local var
        for var in "${!__DELIMITED_VARS[@]}"; do
            if is-set "$var"; then
                __dump_delimited_var "$var"
            fi
        done

        return
    fi

    local -r default=':'
    local sep=${__DELIMITED_VARS[$name]:-"${default}"}

    local -a ARR=()
    __split "$sep" "${!name}"

    local -i offset=0

    local part
    for part in "${ARR[@]}"; do
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
    local v
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
