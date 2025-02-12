#!/usr/bin/env bash

source ./lib/bash/generate.bash

rc-new-workfile prompt-command
rc-workfile-add-dep "$RC_DEP_POST_INIT"

declare -a PROMPT_COMMAND=()
rc-declare PROMPT_COMMAND

__rc_add_prompt_command() {
    local -r cmd=${1?command required}

    timer start "__rc_add_prompt_command($cmd)"

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

    timer stop
}
rc-workfile-add-function __rc_add_prompt_command

_dump_func() {
    local -r name=${1:?}
    local -r body=${2:?}
    bash \
        --norc \
        --noprofile \
        -c "$body; declare -f ${name}"
}

if rc-command-exists direnv; then
    _direnv_hook=$(_dump_func _direnv_hook "$(direnv hook bash)")

    rc-workfile-append-line "$_direnv_hook"
    rc-workfile-add-exec __rc_add_prompt_command _direnv_hook

elif rc-command-exists mise; then
    script=$(mise activate bash)

    mise=$(_dump_func mise "$script")
    _mise_hook=$(_dump_func _mise_hook "$script")

    rc-workfile-append-line '# shellcheck disable=all'
    rc-workfile-append-line '{'
    rc-workfile-append-line 'export MISE_SHELL=bash'
    rc-workfile-append      'export __MISE_ORIG_PATH="%s"\n' \$PATH
    rc-workfile-append-line "$mise"
    rc-workfile-append-line "$_mise_hook"
    rc-workfile-add-exec __rc_add_prompt_command _mise_hook
    rc-workfile-add-exec _mise_hook
    rc-workfile-append-line '}'
fi

rc-workfile-close
