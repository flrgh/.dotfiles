if [[ -d $HOME/.config/nvm ]]; then
    export NVM_DIR="$HOME/.config/nvm"

    # lazy-load nvm since it's pretty slow
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then

        if ! iHave nvm; then
            nvm() {
                unset -f nvm
                . "$NVM_DIR/nvm.sh"

                nvm "$@"
            }
        fi

        if ! iHave node; then
            node() {
                unset -f node
                . "$NVM_DIR/nvm.sh"

                node "$@"
            }

        fi
    fi

    _source_file "$NVM_DIR/bash_completion"
fi
