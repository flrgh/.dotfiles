#!/usr/bin/env bash

source ./lib/bash/generate.bash

if ! rc-command-exists fzf; then
    log "fzf is not installed"
    exit 0
fi


rc-new-workfile fzf
rc-workfile-add-dep "$RC_DEP_POST_INIT"
rc-workfile-add-dep "$RC_DEP_SET_VAR"

rc-export FZF_DEFAULT_OPTS "--info=default --height=80% --border=sharp --tabstop=4"

rc-workfile-if-interactive

if rc-command-exists fd; then
    log "fd is installed, adding some fzf support functions"

    cmd='fd --hidden --type f --color=never --exclude ".git"'
    rc-export FZF_DEFAULT_COMMAND "$cmd"
    rc-export FZF_CTRL_T_COMMAND "$cmd"

    _fzf_compgen_path() {
        command fd --hidden --follow --exclude ".git" . "$1"
    }
    rc-workfile-add-function _fzf_compgen_path

    _fzf_compgen_dir() {
        command fd --type d --hidden --follow --exclude ".git" . "$1"
    }
    rc-workfile-add-function _fzf_compgen_dir
fi

{
    log "extracting bash key bindings"

    BINDINGS=$BUILD_ROOT/fzf/key-bindings.bash
    mkdir -p "$(dirname "$BINDINGS")"

    fzf --bash \
        | sed -n '/### key-bindings.bash ###/,/### end: key-bindings.bash ###/p' \
        > "$BINDINGS"

        patch "$BINDINGS" ./patch/fzf-key-bindings.bash.patch

    log "patching bash key bindings"
    rc-workfile-include-external "$BINDINGS"
}

rc-workfile-fi

rc-workfile-close
