# options for fzf
if iHave fzf; then
    if [[ -f /usr/share/fzf/shell/key-bindings.bash ]]; then
        . /usr/share/fzf/shell/key-bindings.bash
    fi

    FZF_DEFAULT_OPTS="--info=default --height=80% --border=sharp --tabstop=4"

    if iHave fd; then
        export FZF_DEFAULT_COMMAND='fd --type f --color=never'
        #export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        #export FZF_ALT_C_COMMAND='fd --type d . --color=never'
    fi
fi
