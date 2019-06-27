#!/bin/bash

DOTFILES_DIRECTORY="$PWD"

mkdir -p "$HOME/.dotfiles.old"
mkdir -p "$HOME/.local"

for item in .vim .vimrc .tmux.conf .bash .bash_profile .bashrc; do
    if [[ -L "$HOME/$item" ]]; then
        rm "$HOME/$item"
    elif [[ -f "$HOME/$item" || -d "$HOME/$item" ]]; then
        mv "$HOME/$item" "$HOME/.dotfiles.old/"
    fi
    ln -s "$DOTFILES_DIRECTORY/$item" "$HOME/$item"
done

mkdir -vp "$HOME/.config/nvim"
cp -v init.vim "$HOME/.config/nvim/"

ln -s "$DOTFILES_DIRECTORY/.startup.py" "$HOME/.local/.startup.py"

# Set up Vundle for vim
git submodule update --init

echo "Installing vim plugins"
\vim --not-a-term +BundleInstall +qall

echo "Installing neovim plugins"
nvim --headless +PlugUpdate +qall
