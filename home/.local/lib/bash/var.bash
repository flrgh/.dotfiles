# returns 0 if the first argument is a valid variable name/identifier
is-valid-identifier() {
    [[ ${1:-} = [a-zA-Z_]*([a-zA-Z_0-9]) ]]
}

var-dec() {
    local -r name=${1?var name is required}
    local -r dest=${2?dest var is required}

    if ! is-valid-identifier "$name"; then
        return 1
    fi

    printf -v "$dest" '%s' "$(builtin declare -p "$name" 2>/dev/null)"

    [[ -n "${!dest:-}" ]]
}

# Given a variable name, sets the following variables:
#
# VAR_VALID            0|1    # name is a valid bash identifier
# VAR_DECLARED         0|1    # variable was declared
# VAR_DECLARATION      string # entire `declare [opt...] <name>[=<value>]` string
# VAR_FLAGS            string # flags from the `declare` string
# VAR_VALUE            string # value component of the `declare` string
# VAR_IS_SET           0|1    # whether or not the variable has been set to any (even empty) value
# VAR_IS_NON_EMPTY     0|1    # if the string or array length of the value is greater than 0
# VAR_STRING_LEN       int    # length of non-array variables
# VAR_ARRAY_LEN        int    # length of array-type variables
# VAR_FLAG_EXPORTED    0|1    # variable is exported
# VAR_FLAG_NAMEREF     0|1    # variable has the nameref attribute
# VAR_FLAG_INTEGER     0|1    # variable has the integer attribute
# VAR_FLAG_ARRAY       0|1    # variable is an array with numeric indices
# VAR_FLAG_ASSOC_ARRAY 0|1    # variable is an associative array
# VAR_FLAG_LOWERCASE   0|1    # variable has the lowercase attribute
# VAR_FLAG_UPPERCASE   0|1    # variable has the uppercase attribute
# VAR_FLAG_READONLY    0|1    # variable is readonly
# VAR_FLAG_TRACE       0|1    # variable has the trace attribute
#
var-info() {
    local -r name=${1?var name is required}

    VAR_VALID=0
    VAR_DECLARED=0
    VAR_DECLARATION=""
    VAR_FLAGS=""
    VAR_VALUE=""
    VAR_IS_SET=0
    VAR_IS_NON_EMPTY=0
    VAR_STRING_LEN=0
    VAR_ARRAY_LEN=0

    # attributes
    VAR_FLAG_EXPORTED=0
    VAR_FLAG_NAMEREF=0
    VAR_FLAG_INTEGER=0
    VAR_FLAG_ARRAY=0
    VAR_FLAG_ASSOC_ARRAY=0
    VAR_FLAG_LOWERCASE=0
    VAR_FLAG_UPPERCASE=0
    VAR_FLAG_READONLY=0
    VAR_FLAG_TRACE=0

    if ! is-valid-identifier "$name"; then
        return 1
    fi

    VAR_VALID=1

    local dec
    if ! var-dec "$name" dec; then
        # undeclared
        return 1
    fi

    VAR_DECLARED=1
    VAR_DECLARATION="$dec"

    local flags=${dec#declare }
    flags=${flags%% *}

    VAR_FLAGS="$flags"
    local i
    for (( i = 0; i < ${#flags}; i++ )); do
        case ${flags:${i}:1} in
            a) VAR_FLAG_ARRAY=1       ;;
            A) VAR_FLAG_ASSOC_ARRAY=1 ;;
            i) VAR_FLAG_INTEGER=1     ;;
            l) VAR_FLAG_LOWERCASE=1   ;;
            u) VAR_FLAG_UPPERCASE=1   ;;
            x) VAR_FLAG_EXPORTED=1    ;;
            n) VAR_FLAG_NAMEREF=1     ;;
            r) VAR_FLAG_READONLY=1    ;;
            t) VAR_FLAG_TRACE=1       ;;
        esac
    done

    local value=${dec#declare -}
    value=${value#* "$name"}
    value=${value#=}

    if [[ -n $value ]]; then
        VAR_IS_SET=1

        value=${value%\"}
        value=${value#\"}
        VAR_VALUE="$value"

        if [[ -n $value && $value != '()' ]]; then
            VAR_IS_NON_EMPTY=1
        fi
    fi

    if (( VAR_FLAG_ARRAY == 1 )); then
        local -a scratch="$value"
        VAR_ARRAY_LEN=${#scratch[@]}

    elif (( VAR_FLAG_ASSOC_ARRAY == 1 )); then
        local -A scratch="$value"
        VAR_ARRAY_LEN=${#scratch[@]}

    else
        VAR_STRING_LEN=${#value}
    fi
}
