if [[ $OSTYPE =~ linux ]]; then
    alias ls='ls --color=auto'
elif [[ $OSTYPE =~ darwin ]]; then
    alias ls='ls -laG'
fi

alias grep='grep --color=auto'


if command -v nvim &>/dev/null; then
    alias vim=nvim
fi
