#!/usr/bin/env bash

source "$REPO_ROOT"/lib/bash/generate.bash

readonly DEST=prompt-command

append() {
    bashrc-pref "$DEST" "$@"
}

add-function() {
    local -r name=$1

    local body
    if body=$(declare -f "$name" 2>/dev/null); then
        append '%s\n' "$body"

    else
        echo "function $name not found"
    fi
}

PROMPT_ARRAY=0
DIRENV_HOOK=

# as of bash 5.1, PROMPT_COMMAND can be an array, _but_ this was not supported
# by direnv until 2.34.0
if (( BASH_VERSINFO[0] > 5 )) || (( BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 1 )); then
    if bashrc-command-exists direnv; then
        readonly MIN_VERSION=2.34.0

        if direnv version "$MIN_VERSION" &>/dev/null; then
            echo "direnv has array support for PROMPT_COMMAND"
            PROMPT_ARRAY=1
        fi

        DIRENV_HOOK=$(direnv hook bash)

    else
        echo "direnv not installed"
        PROMPT_ARRAY=1
    fi
fi

if (( PROMPT_ARRAY == 1 )); then
    declare -a PROMPT_COMMAND=()
    bashrc-pre-declare PROMPT_COMMAND

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
    bashrc-pre-exec "$DEST" unset PROMPT_COMMAND

    __rc_add_prompt_command() {
        local -r cmd=${1?command required}
        __rc_add_path --prepend --sep ";" PROMPT_COMMAND "$cmd"
    }
fi

bashrc-pre-function __rc_add_prompt_command


if [[ -n $DIRENV_HOOK ]]; then
    bashrc-includef direnv "# shellcheck disable=SC2128\n"
    bashrc-includef direnv "# shellcheck disable=SC2178\n"
    bashrc-includef direnv "{\n%s\n}\n" "$DIRENV_HOOK"
fi
