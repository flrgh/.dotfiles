# options for fzf
if iHave fzf; then
    FZF_DEFAULT_OPTS="--info=default --height=80% --border=sharp --tabstop=4"

    if iHave fd; then
        export FZF_DEFAULT_COMMAND='fd --hidden --type f --color=never'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

        _fzf_compgen_path() {
            fd --hidden --follow --exclude ".git" . "$1"
        }

        _fzf_compgen_dir() {
            fd --type d --hidden --follow --exclude ".git" . "$1"
        }

        #export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        #export FZF_ALT_C_COMMAND='fd --type d . --color=never'
    fi

    if [[ -f /usr/share/fzf/shell/key-bindings.bash ]]; then
        _source_file /usr/share/fzf/shell/key-bindings.bash
    fi
fi
