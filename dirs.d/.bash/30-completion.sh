#
# Tab completion
#

if [[ -f /etc/profile.d/bash_completion.sh ]]; then
    _debug_rc "sourcing system bash completion"
    . /etc/profile.d/bash_completion.sh
fi

# Git
if [[ -f $HOME/.git-completion.bash ]]; then
    _debug_rc "sourcing git bash completion"
  . "$HOME/.git-completion.bash"
fi

# homebrew bash completion
if [[ $OSTYPE =~ darwin ]]; then
    if iHave brew; then
        brew_prefix=$(brew --prefix)
        if [[ -f $brew_prefix/etc/bash_completion ]]; then
            . "${brew_prefix}/etc/bash_completion"
        fi
        unset brew_prefix
    fi
fi

# local bash completion
_source_dir "$HOME/.local/.bash_completion.d"
