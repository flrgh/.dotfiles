declare -g BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}

if (( ${BASH_USER_LIB_RELOAD:-0} )); then
    unset -v BASH_USER_LIB_SOURCED
fi

unset -v BASH_USER_LIB_RELOAD

if ! declare -p BASH_USER_LIB_SOURCED &>/dev/null; then
    declare -gA BASH_USER_LIB_SOURCED=()
fi

declare -gi BASH_USER_5_3=0
if (( BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 3 )); then
    BASH_USER_5_3=1
fi
