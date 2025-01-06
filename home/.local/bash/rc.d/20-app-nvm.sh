export NVM_DIR="$HOME/.config/nvm"

if [[ -d $NVM_DIR ]]; then

    # lazy-load nvm since it's really slow
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        nvm() {
            unset -f nvm
            . "$NVM_DIR/nvm.sh"
            nvm use --lts
            nvm "$@"
        }

        if [[ -e $NVM_DIR/bash_completion ]]; then
            __complete_nvm() {
                unset -f __complete_nvm
                complete -r nvm

                source "$NVM_DIR/bash_completion" && return 124
            }

            complete -o default -F __complete_nvm nvm
        fi
    fi

    # sourcing $NVM_DIR/nvm.sh does this for us, but it's slow
    if __rc_function_exists node; then
        __rc_debug "unset-ing legacy node function"
        unset -f node
    fi

    if ! __rc_binary_exists node; then
        node_paths=("$NVM_DIR"/versions/node/*)

        if (( ${#node_paths[@]} > 0 )); then
            # globs are sorted, so this _should_ give us the most recent version
            use_node=${node_paths[-1]}
            __rc_debug "Found nvm node at $use_node"

            export NVM_BIN="$use_node/bin"
            __rc_add_path PATH "$NVM_BIN"

            export NVM_INC="$use_node/include/node"

            unset use_node
        fi

        unset node_paths
    fi
fi
