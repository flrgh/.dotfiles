#
# Tab completion
#

if [ -f /etc/profile.d/bash_completion.sh ]; then
    . /etc/profile.d/bash_completion.sh
fi

# Git
if [[ -f $HOME/.git-completion.bash ]]; then
  . "$HOME/.git-completion.bash"
fi

# homebrew bash completion
if [[ $OSTYPE =~ darwin ]]; then
    if command -v brew &>/dev/null; then
        brew_prefix=$(brew --prefix)
        if [[ -f $brew_prefix/etc/bash_completion ]]; then
            . "${brew_prefix}/etc/bash_completion"
        fi
    fi
fi

# local bash completion
if [[ -d $HOME/.local/.bash_completion.d ]]; then
    for f in "$HOME"/.local/.bash_completion.d/*; do
        . "$f"
    done
fi