#!/usr/bin/env bash

source "$REPO_ROOT"/lib/bash/generate.bash

readonly DEST=nvm

export NVM_DIR="$HOME/.config/nvm"
bashrc-includef "$DEST" 'export %s=%q\n' NVM_DIR "$NVM_DIR"

if [[ ! -d $NVM_DIR ]]; then
    exit 0
fi

# lazy-load nvm since it's really slow
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    nvm() {
        unset -f nvm
        # shellcheck disable=SC1091
        . "$NVM_DIR/nvm.sh"
        nvm "$@"
    }
    bashrc-includef "$DEST" '%s\n' "$(declare -f nvm)"

    if [[ -e $NVM_DIR/bash_completion ]]; then
        __complete_nvm() {
            unset -f __complete_nvm
            complete -r nvm

            # shellcheck disable=SC1091
            source "$NVM_DIR/bash_completion" && return 124
        }
        bashrc-includef "$DEST" '%s\n' "$(declare -f __complete_nvm)"
        bashrc-includef "$DEST" '%s\n' 'complete -o default -F __complete_nvm nvm'
    fi
fi

# sourcing $NVM_DIR/nvm.sh does this for us, but it's slow
if declare -f node &>/dev/null; then
    echo "unset-ing legacy node function"
    bashrc-includef "$DEST" '%s\n' 'unset -f node'
fi

# shellcheck disable=SC1091
source "$NVM_DIR/nvm.sh"
nvm use --lts
NODE=$(nvm which current)

if [[ -n $NODE ]]; then
    NVM_BIN=${NODE%/node}
    bashrc-includef "$DEST" 'export NVM_BIN=%q\n' "$NVM_BIN"
    bashrc-includef "$DEST" '__rc_add_path PATH %q\n' "$NVM_BIN"

    NVM_INC=${NODE%/bin/node}/include/node
    bashrc-includef "$DEST" 'export NVM_INC=%q\n' "$NVM_INC"
fi
