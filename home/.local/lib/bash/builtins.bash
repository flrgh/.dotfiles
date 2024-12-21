BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}
source "$BASH_USER_LIB"/__init.bash

# not doing the auto-return thing here because I just
# want to make sure custom builtins are always loaded
#
#(( BASH_USER_LIB_SOURCED[builtins]++ == 0 )) || return 0
: $(( BASH_USER_LIB_SOURCED[builtins]++ == 0 ))

declare -gx BASH_USER_BUILTINS_PATH=$HOME/.local/lib/bash/builtins
declare -gxA BASH_USER_BUILTINS=()
declare -gxA BASH_USER_BUILTINS_SOURCE=(
    [pathset]="$BASH_USER_BUILTINS_PATH/libbash_builtin_extras.so"
)

__have_builtin() {
    local -r name=$1
    [[ $(type -t "$name" 2>/dev/null) == "builtin" ]]
}

__load_builtin() {
    local -r name=$1
    local -r path=${2:-${BASH_USER_BUILTINS_SOURCE[$name]}}

    BASH_USER_BUILTINS[$name]=0

    if __have_builtin "$name"; then
        BASH_USER_BUILTINS[$name]=1
        return 0
    fi

    if [[ ! -e $path ]]; then
        return 1
    fi

    if enable -f "$path" "$name"; then
        BASH_USER_BUILTINS[$name]=1
        return 0
    fi

    return 1
}

for __name in "${!BASH_USER_BUILTINS_SOURCE[@]}"; do
    __load_builtin "$__name"
done

unset __name
unset -f __have_builtin __load_builtin
