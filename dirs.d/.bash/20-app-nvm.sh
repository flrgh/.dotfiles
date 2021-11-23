if [[ -d $HOME/.config/nvm ]]; then
    export NVM_DIR="$HOME/.config/nvm"

    # lazy-load nvm since it's pretty slow
    nvm() {
        if [[ ${_NVM_SOURCED:-0} != 1 ]]; then
            unset -f nvm

            if [[ -s $NVM_DIR/nvm.sh ]]; then
                . "$NVM_DIR/nvm.sh"
            fi

            nvm "$@"
        fi
    }

    _source_dir "$NVM_DIR/bash_completion"
fi
