if [[ -d $HOME/.config/nvm ]]; then
    export NVM_DIR="$HOME/.config/nvm"

    if [[ -s $NVM_DIR/nvm.sh ]]; then
        . "$NVM_DIR/nvm.sh"
    fi

    if [[ -s $NVM_DIR/bash_completion ]]; then
        . "$NVM_DIR/bash_completion"
    fi
fi
