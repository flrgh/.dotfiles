# start with a blank slate
unalias -a

alias grep='grep --color=auto'

if __rc_command_exists lsd; then
    alias ls="lsd -l"
fi

alias ..='cd ..'
