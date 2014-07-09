#!/bin/bash

DOTFILES_DIRECTORY="$(dirname "$(readlink -f ${BASH_SOURCE[0]})")"

mkdir -p "$HOME/.dotfiles.old"

for item in .vim .vimrc .tmux.conf .bash_profile .bashrc; do
    if [ -L "$HOME/$item" ] ; then
        rm "$HOME/$item"
    elif [ -f "$HOME/$item" -o -d "$HOME/$item" ] ; then
        mv "$HOME/$item" "$HOME/.dotfiles.old/"
    fi
    ln -s "$DOTFILES_DIRECTORY/$item" "$HOME/$item"
done
