#!/usr/bin/env bash

export MISE_INSTALL_PATH=$HOME/.local/bin/mise

if [[ -z ${GITHUB_TOKEN:-} ]]; then
    if [[ -e $HOME/.config/github/helper-access-token ]]; then
        source "$HOME/.config/github/helper-access-token"
    fi
fi
if [[ -n ${GITHUB_TOKEN:-} ]]; then
    export GITHUB_API_TOKEN=${GITHUB_TOKEN}
fi

if [[ -x $MISE_INSTALL_PATH ]]; then
    "$MISE_INSTALL_PATH" self-update --yes
else
    export MISE_INSTALL_HELP=1
    export MISE_DEBUG=1
    export MISE_QUIET=0
    curl https://mise.run | sh
fi

"$MISE_INSTALL_PATH" upgrade
