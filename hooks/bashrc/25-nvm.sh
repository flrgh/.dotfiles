#!/usr/bin/env bash

source ./lib/bash/generate.bash
source ./lib/bash/facts.bash

rc-new-workfile nvm
rc-workfile-add-dep "$RC_DEP_SET_VAR"
rc-workfile-add-dep "rc-pathset"

shopt -s nullglob

rc-require-var NVM_DIR
rc-export NVM_DIR

if have varsplice gte "0.2"; then
    rc-varsplice --remove -g PATH "${NVM_DIR:?}/*"
else
    for bin in "$NVM_DIR"/versions/node/*/bin; do
        rc-add-path PATH "$bin"
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

    rc-workfile-add-function nvm

    if [[ -e $NVM_DIR/bash_completion ]]; then
        __complete_nvm() {
            unset -f __complete_nvm
            complete -r nvm

            # shellcheck disable=SC1091
            source "$NVM_DIR/bash_completion" && return 124
        }

        rc-workfile-add-function __complete_nvm
        rc-workfile-add-exec complete -o default -F __complete_nvm nvm
    fi
fi

# sourcing $NVM_DIR/nvm.sh does this for us, but it's slow
rc-workfile-add-exec unset -f node

# shellcheck disable=SC1091
source "$NVM_DIR/nvm.sh"
nvm use --lts
NODE=$(nvm which current)

if [[ -n $NODE ]]; then
    NVM_BIN=${NODE%/node}
    rc-export NVM_BIN "$NVM_BIN"
    rc-add-path PATH "$NVM_BIN"

    NVM_INC=${NODE%/bin/node}/include/node
    rc-export NVM_INC "$NVM_INC"
fi
