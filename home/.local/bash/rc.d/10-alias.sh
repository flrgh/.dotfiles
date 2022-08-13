alias grep='grep --color=auto'

if iHave nvim &>/dev/null; then
    _debug_rc "neovim is installed; aliasing vim=nvim"
    alias vim=nvim
fi

if iHave lsd; then
    alias ls="lsd -l"
fi
