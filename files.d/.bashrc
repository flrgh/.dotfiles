if [[ -d $HOME/.bash ]]; then
    for file in "$HOME"/.bash/*; do
        . "$file"
    done
fi
