export BASH_ENV="$HOME"/.config/env

if [[ -n ${BASH:-} ]]; then
    source "$HOME"/.bashrc

elif [[ -e $BASH_ENV ]]; then
    # .bashrc will source this file otherwise
    source "$BASH_ENV"
fi
