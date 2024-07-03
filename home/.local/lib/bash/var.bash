BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}
source "$BASH_USER_LIB"/__init.bash
(( BASH_USER_LIB_SOURCED[var]++ == 0 )) || return 0

unset VAR_INFO
declare -gA VAR_INFO

# returns 0 if the first argument is a valid variable name/identifier
is-valid-identifier() {
    [[ ${1:-} = [a-zA-Z_]*([a-zA-Z_0-9]) ]]
}

var-dec() {
    local -r name=${1:?var name is required}
    local -r dest=${2:?dest var is required}

    if ! is-valid-identifier "$name"; then
        return 1
    fi

    printf -v "$dest" '%s' "$(builtin declare -p "$name" 2>/dev/null)"

    [[ -n "${!dest:-}" ]]
}

declare -g VAR_FLAGS
declare -g VAR_VALUE

__parse_decl() {
    VAR_FLAGS=""
    VAR_VALUE=""

    local -r name=${1:?var name is required}

    local __decl; __decl=$(builtin declare -p "$name" 2>/dev/null || true)

    if [[ -z $__decl ]]; then
        return 1
    fi

    VAR_FLAGS=${__decl##"declare -"}
    VAR_FLAGS=${VAR_FLAGS#"-"}

    VAR_VALUE=${VAR_FLAGS#* *=}
    VAR_VALUE=${VAR_VALUE#\"}
    VAR_VALUE=${VAR_VALUE%\"}

    VAR_FLAGS=${VAR_FLAGS%% *}
}

# Given a variable name, fills a global VAR_INFO associative array with
# the variable's metadata. The VAR_INFO array has the following keys:
#
# VAR_INFO[is_valid]       bool   # name is a valid bash identifier
# VAR_INFO[is_declared]    bool   # variable was declared
# VAR_INFO[declaration]    string # entire `declare [opt...] <name>[=<value>]` string
# VAR_INFO[flags]          string # flags from the `declare` string
# VAR_INFO[value]          string # value component of the `declare` string
# VAR_INFO[is_set]         bool   # whether or not the variable has been set to any (even empty) value
# VAR_INFO[is_non_empty]   bool   # if the string or array length of the value is greater than 0
# VAR_INFO[len]            int    # for arrays, the number of items, else the string length
# VAR_INFO[is_exported]    bool   # variable is exported
# VAR_INFO[is_nameref]     bool   # variable has the nameref attribute
# VAR_INFO[is_integer]     bool   # variable has the integer attribute
# VAR_INFO[is_array]       bool   # variable is an array with numeric indices
# VAR_INFO[is_assoc_array] bool   # variable is an associative array
# VAR_INFO[is_lowercase]   bool   # variable has the lowercase attribute
# VAR_INFO[is_uppercase]   bool   # variable has the uppercase attribute
# VAR_INFO[is_readonly]    bool   # variable is readonly
# VAR_INFO[is_trace]       bool   # variable has the trace attribute
#
# Keys marked as `bool` are set to `1` if truthy and otherwise may be unset or
# explicitly set to `0`.
var-info() {
    local -r name=${1?var name is required}

    VAR_INFO=(
        [is_valid]=0
        [is_declared]=0
        [name]="$name"
    )

    if ! is-valid-identifier "$name"; then
        return 1
    fi

    VAR_INFO[is_valid]=1

    local dec
    if ! var-dec "$name" dec; then
        # undeclared
        return 1
    fi

    VAR_INFO[is_declared]=1
    VAR_INFO[declaration]="$dec"

    local flags=${dec#declare }
    flags=${flags%% *}

    VAR_INFO[flags]="$flags"
    local i
    for (( i = 0; i < ${#flags}; i++ )); do
        case ${flags:${i}:1} in
            a) VAR_INFO[is_array]=1       ;;
            A) VAR_INFO[is_assoc_array]=1 ;;
            i) VAR_INFO[is_integer]=1     ;;
            l) VAR_INFO[is_lowercase]=1   ;;
            u) VAR_INFO[is_uppercase]=1   ;;
            x) VAR_INFO[is_exported]=1    ;;
            n) VAR_INFO[is_nameref]=1     ;;
            r) VAR_INFO[is_readonly]=1    ;;
            t) VAR_INFO[is_trace]=1       ;;
        esac
    done

    local value=${dec#declare -}
    value=${value#* "$name"}
    value=${value#=}

    VAR_INFO[len]=0

    if [[ -n $value ]]; then
        VAR_INFO[is_set]=1

        value=${value%\"}
        value=${value#\"}
        VAR_INFO[value]="$value"

        if [[ -n $value && $value != '()' ]]; then
            VAR_INFO[is_non_empty]=1
        fi
    fi

    if (( VAR_INFO[is_array] )); then
        if (( VAR_INFO[is_set] )); then
            local -a scratch="$value"
            VAR_INFO[len]=${#scratch[@]}
        fi

    elif (( VAR_INFO[is_assoc_array] )); then
        if (( VAR_INFO[is_set] )); then
            local -A scratch="$value"
            VAR_INFO[len]=${#scratch[@]}
        fi

    elif (( VAR_INFO[is_non_empty] )); then
        VAR_INFO[len]=${#value}
    fi

    if (( VAR_INFO[is_nameref] && VAR_INFO[is_non_empty] )); then
        VAR_INFO[nameref_target]="$value"
    fi
}
