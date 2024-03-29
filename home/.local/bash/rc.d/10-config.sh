# General shell options

# Use vim!
export EDITOR=vim

# globbing should get files/directories that start with .
shopt -s dotglob

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
if [[ -x /usr/bin/lesspipe ]]; then
    eval "$(SHELL=/bin/sh lesspipe)"
fi

# use bat as a man pager if it exists
if iHave bat; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT="-c"
fi

# I hate this thing
if iHave command_not_found_handle; then
    _debug_rc "unsetting command_not_found_handle func"
    unset -f command_not_found_handle
fi

export PS1="\[\e[0;36m\]\u@\h\[\e[m\] \[\e[0;34m\]\w\[\e[m\] \[\e[0;33m\]\[\e[m\]\$ "
