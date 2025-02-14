#!/usr/bin/env bash

source ./lib/bash/generate.bash

declare -ga PROMPT_COMMAND=()

_dump_func() {
    local -r name=${1:?}
    local -r body=${2:?}
    bash \
        --norc \
        --noprofile \
        -c "$body; declare -f ${name}"
}

emit-history-command() {
    rc-workfile-include ./bash/update-history.bash
    PROMPT_COMMAND+=(__check_history)
}

emit-status-command() {
    rc-workfile-include ./bash/conf-color-prompt.sh
    PROMPT_COMMAND+=(__last_status)
}


emit-env-command() {
    if rc-command-exists direnv; then
        _direnv_hook=$(_dump_func _direnv_hook "$(direnv hook bash)")

        rc-workfile-append-line "$_direnv_hook"
        PROMPT_COMMAND+=(_direnv_hook)

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
        rc-workfile-add-exec _mise_hook
        rc-workfile-append-line '}'
        PROMPT_COMMAND+=(_mise_hook)
    fi
}

main() {
    rc-new-workfile prompt-command
    rc-workfile-add-dep "$RC_DEP_POST_INIT"
    rc-workfile-add-dep "$RC_DEP_SET_VAR"

    emit-history-command
    emit-status-command
    emit-env-command

    rc-workfile-append-line "${PROMPT_COMMAND[*]@A}"

    rc-workfile-close
}

main "$@"
