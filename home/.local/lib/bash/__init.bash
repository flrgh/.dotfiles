declare -g BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}

if (( ${BASH_USER_LIB_RELOAD:-0} )); then
    unset -v BASH_USER_LIB_SOURCED
fi

unset -v BASH_USER_LIB_RELOAD

if ! declare -p BASH_USER_LIB_SOURCED &>/dev/null; then
    declare -gA BASH_USER_LIB_SOURCED=()
fi
