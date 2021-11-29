export NVM_DIR="$HOME/.config/nvm"

if [[ -d $NVM_DIR ]]; then

    # lazy-load nvm since it's really slow
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        nvm() {
            unset -f nvm
            . "$NVM_DIR/nvm.sh"
            nvm "$@"
        }

        export nvm
    fi

    # sourcing $NVM_DIR/nvm.sh does this for us, but it's slow
    if isFunction node; then
        _debug_rc "unset-ing legacy node function"
        unset -f node
    fi

    if ! isExe node; then
        node_paths=("$NVM_DIR"/versions/node/*)

        if (( ${#node_paths[@]} > 0 )); then
            # globs are sorted, so this _should_ give us the most recent version
            use_node=${node_paths[-1]}
            _debug_rc "Found nvm node at $use_node"

            export NVM_BIN="$use_node/bin"
            addPath "$NVM_BIN"

            export NVM_INC="$use_node/include/node"

            unset use_node
        fi

        unset node_paths
    fi

    _source_file "$NVM_DIR/bash_completion"
fi
