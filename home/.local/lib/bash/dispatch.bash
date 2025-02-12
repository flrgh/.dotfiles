BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}
source "$BASH_USER_LIB"/__init.bash
(( BASH_USER_LIB_SOURCED[dispatch]++ == 0 )) || return 0

__function_dispatch() {
    local -r fn=${FUNCNAME[1]:?could not detect function name}
    local -r src="${BASH_USER_LIB}/functions/${fn}.bash"
    if [[ ! -r $src ]]; then
        echo "ERROR: source file for function ${fn} ($src) does not exist" >&2
        return 127
    fi

    builtin unset -f "$fn"

    # shellcheck disable=SC1090
    builtin source "$src"

    if ! builtin declare -F "$fn" &>/dev/null; then
        echo "ERROR: function ${fn} not defined by source file ($src)" >&2
        return 127
    fi

    "$fn" "$@"
}
