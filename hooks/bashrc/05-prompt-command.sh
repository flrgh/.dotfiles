#!/usr/bin/env bash

source ./lib/bash/generate.bash

rc-new-workfile prompt-command
rc-workfile-add-dep "$RC_DEP_POST_INIT"

if rc-command-exists direnv; then
    set-have direnv
    set-version direnv "$(direnv version)"
else
    set-not-have direnv
fi

PROMPT_ARRAY=0
DIRENV_HOOK=

# as of bash 5.1, PROMPT_COMMAND can be an array, _but_ this was not supported
# by direnv until 2.34.0
if have bash gte "5.1"; then
    if have direnv gte "2.34"; then
        echo "direnv has array support for PROMPT_COMMAND"
        PROMPT_ARRAY=1
        DIRENV_HOOK=$(direnv hook bash)

    else
        echo "direnv not installed"
        PROMPT_ARRAY=1
    fi
fi

if (( PROMPT_ARRAY == 1 )); then
    declare -a PROMPT_COMMAND=()
    rc-declare PROMPT_COMMAND

    __rc_add_prompt_command() {
        local -r cmd=${1?command required}

        __rc_timer_start "__rc_add_prompt_command($cmd)"

        local -a new=()

        local elem
        for elem in "${PROMPT_COMMAND[@]}"; do
            if [[ $elem == "$cmd" ]]; then
                continue
            fi
            new+=("$elem")
        done

        # prepend for consistency with `__rc_add_path`
        PROMPT_COMMAND=("$cmd" "${new[@]}")

        __rc_timer_stop
    }
else
    rc-reset-var PROMPT_COMMAND

    __rc_add_prompt_command() {
        local -r cmd=${1?command required}
        __rc_add_path --prepend --sep ";" PROMPT_COMMAND "$cmd"
    }
fi

rc-workfile-add-function __rc_add_prompt_command

if [[ -n $DIRENV_HOOK ]]; then
    unset -f _direnv_hook
    eval "$DIRENV_HOOK"

    if declare -F _direnv_hook; then
        rc-workfile-add-function _direnv_hook
        rc-workfile-add-exec __rc_add_prompt_command _direnv_hook
    else
        rc-workfile-append "# shellcheck disable=SC2128\n"
        rc-workfile-append "# shellcheck disable=SC2178\n"
        rc-workfile-append "{\n%s\n}\n" "$DIRENV_HOOK"
    fi
fi
