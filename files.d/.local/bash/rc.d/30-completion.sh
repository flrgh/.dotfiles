#
# Tab completion
#

if [[ -f /etc/profile.d/bash_completion.sh ]]; then
    _debug_rc "sourcing system bash completion"
    _source_file /etc/profile.d/bash_completion.sh
fi

# Git
if [[ -f $HOME/.git-completion.bash ]]; then
    _debug_rc "sourcing git bash completion"
  _source_file "$HOME/.git-completion.bash"
fi

# homebrew bash completion
if [[ $OSTYPE =~ darwin ]]; then
    if iHave brew; then
        brew_prefix=$(brew --prefix)
        if [[ -f $brew_prefix/etc/bash_completion ]]; then
            _source_file "${brew_prefix}/etc/bash_completion"
        fi
        unset brew_prefix
    fi
fi

# local bash completion
_source_dir "$HOME/.local/bash/completion.d"
