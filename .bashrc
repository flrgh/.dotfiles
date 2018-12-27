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

if [ -f /etc/profile.d/bash_completion.sh ]; then
    . /etc/profile.d/bash_completion.sh
fi

# Git
if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

# homebrew bash completion
if [[ $macOS ]]; then
    brew_prefix=$(brew --prefix)
    if [ -f $brew_prefix/etc/bash_completion ]; then
            . "${brew_prefix}/etc/bash_completion"
    fi
fi

#
# General shell options
#

# Use vim!
export EDITOR=vim

# globbing should get files/directories that star with .
shopt -s dotglob

# Bash History configuration
#
# Don't save commmands that start with a space
export HISTCONTROL=ignorespace
# History is valuable; let's keep lots of it
export HISTFILESIZE=100000
export HISTSIZE=1000
# timestamps with history
export HISTTIMEFORMAT='%F %T '
# save+reload history after every command
# this could get expensive and slow when the history file gets big
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Use readline backward-kill-word instead of tty werase
# I prefer this because backward-kill-word uses whitespace and the forward slash ("/") for word boundaries
if [[ $- == *i* ]]; then
    stty werase undef
    bind '"\C-w": backward-kill-word'
fi

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

# Make ssh agent forwarding work with persistent tmux/screen sessions
if [[ -S "$SSH_AUTH_SOCK" && ! -h "$SSH_AUTH_SOCK" ]]; then
    ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock;
fi
export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock;
