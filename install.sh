#!/bin/bash

DOTFILES_DIRECTORY="$PWD"

mkdir -p "$HOME/.dotfiles.old"

for item in .vim .vimrc .tmux.conf .bash_profile .bashrc; do
    if [ -L "$HOME/$item" ] ; then
        rm "$HOME/$item"
    elif [ -f "$HOME/$item" -o -d "$HOME/$item" ] ; then
        mv "$HOME/$item" "$HOME/.dotfiles.old/"
    fi
    ln -s "$DOTFILES_DIRECTORY/$item" "$HOME/$item"
done

mkdir -vp $HOME/.config/nvim
cp -v init.vim $HOME/.config/nvim/

# Set up Vundle for vim
git submodule update --init
vim --not-a-term +BundleInstall +qall
