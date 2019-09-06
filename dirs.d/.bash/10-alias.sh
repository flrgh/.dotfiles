if [[ $OSTYPE =~ linux ]]; then
    alias ls='ls --color=auto'
elif [[ $OSTYPE =~ darwin ]]; then
    alias ls='ls -laG'
fi

alias grep='grep --color=auto'


if command -v nvim &>/dev/null; then
    _debug_rc "neovim is installed; aliasing vim=nvim"
    alias vim=nvim
fi
