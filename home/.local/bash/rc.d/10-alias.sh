alias grep='grep --color=auto'

if __rc_command_exists nvim &>/dev/null; then
    __rc_debug "neovim is installed; aliasing vim=nvim"
    alias vim=nvim
fi

if __rc_command_exists lsd; then
    alias ls="lsd -l"
fi

alias ..='cd ..'
