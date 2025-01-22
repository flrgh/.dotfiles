#!/usr/bin/env bash

source "$REPO_ROOT"/lib/bash/generate.bash

shopt -s nullglob

readonly DEST=nvm

export NVM_DIR="$HOME/.config/nvm"
bashrc-includef "$DEST" 'export %s=%q\n' NVM_DIR "$NVM_DIR"

if [[ -f "$HOME/.local/lib/bash/builtins.bash" ]] \
    && source "$HOME/.local/lib/bash/builtins.bash" \
    && command -v version &>/dev/null \
    && command -v varsplice &>/dev/null \
    && version \
        "${VARSPLICE_VERSION[0]}.${VARSPLICE_VERSION[1]}" \
        gte \
        "0.2"
then
    bashrc-includef "$DEST" 'varsplice --remove -g PATH %q\n' "${NVM_DIR:?}/*"

else
    for bin in "$NVM_DIR"/versions/node/*/bin; do
        bashrc-includef "$DEST" '__rc_rm_path PATH %q\n' "$bin"
    done
fi


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
bashrc-includef "$DEST" '%s\n' 'unset -f node'

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
