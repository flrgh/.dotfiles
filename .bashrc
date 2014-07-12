# First things first, let's detect whether we're on Linux or MacOS
os=$(uname)
if [[ "$os" == "Linux" ]]; then
    LINUX=1
elif [[ "$os" == "Darwin" ]]; then
    macOS=1
fi

#
# Set up common aliases
#
if [ $LINUX ]; then
    alias ls='ls --color=auto'
elif [ $macOS ]; then
    alias ls='ls -laG'
fi
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'

if [ -f ~/.alias ]; then
    source ~/.alias
fi

#
# Tab completion
#

# System
if [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# Git
if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

if [ -d /usr/local/etc/bash_completion.d ]; then
    for f in /usr/local/etc/bash_completion.d/*; do
        source $f
    done
fi


#
# General shell options
#

# globbing should get files/directories that star with .
shopt -s dotglob

# don't put duplicate lines in the history. See bash(1) for more options
# don't overwrite GNU Midnight Commander's setting of `ignorespace'.
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
# ... or force ignoredups and ignorespace
export HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"


#
# Colors
#
export TERM='screen-256color'
export PS1="\[\e[0;36m\]\u@\h\[\e[m\] \[\e[0;34m\]\w\[\e[m\] \[\e[0;33m\]\[\e[m\]\$ "

#
# Local, user-defined stuff
#
if [ -f ~/.local/.bashrc ]; then
    source ~/.local/.bashrc
fi
