#!/usr/bin/env bash

source ./lib/bash/generate.bash

if ! rc-command-exists fzf; then
    exit 0
fi

rc-new-workfile fzf
rc-workfile-add-dep "$RC_DEP_POST_INIT"
rc-workfile-add-dep "$RC_DEP_SET_VAR"

rc-export FZF_DEFAULT_OPTS "--info=default --height=80% --border=sharp --tabstop=4"

if rc-command-exists fd; then
    cmd='fd --hidden --type f --color=never'
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

if [[ -e "$HOME/.local/share/fzf/shell/key-bindings.bash" ]]; then
    rc-workfile-include "$HOME/.local/share/fzf/shell/key-bindings.bash"

elif [[ -f /usr/share/fzf/shell/key-bindings.bash ]]; then
    rc-workfile-include /usr/share/fzf/shell/key-bindings.bash
fi
