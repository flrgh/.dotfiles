#!/usr/bin/env bash

source "$REPO_ROOT"/lib/bash/generate.bash

if bashrc-command-exists fzf; then
    bashrc-export-var FZF_DEFAULT_OPTS "--info=default --height=80% --border=sharp --tabstop=4"

    if bashrc-command-exists fd; then
        cmd='fd --hidden --type f --color=never'
        bashrc-export-var FZF_DEFAULT_COMMAND "$cmd"
        bashrc-export-var FZF_CTRL_T_COMMAND "$cmd"

        _fzf_compgen_path() {
            command fd --hidden --follow --exclude ".git" . "$1"
        }
        bashrc-include-function _fzf_compgen_path

        _fzf_compgen_dir() {
            command fd --type d --hidden --follow --exclude ".git" . "$1"
        }
        bashrc-include-function _fzf_compgen_dir
    fi

    if [[ -e "$HOME/.local/share/fzf/shell/key-bindings.bash" ]]; then
        bashrc-source-file "$HOME/.local/share/fzf/shell/key-bindings.bash"

    elif [[ -f /usr/share/fzf/shell/key-bindings.bash ]]; then
        bashrc-source-file /usr/share/fzf/shell/key-bindings.bash
    fi
fi
