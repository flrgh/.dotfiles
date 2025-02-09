#!/usr/bin/env bash

source ./lib/bash/generate.bash
source ./lib/bash/facts.bash

if rc-command-exists mise; then
    rc-new-workfile node

    mise where node &>/dev/null || {
        mise install node@latest
    }

    NODE=$(mise where node)
    if [[ -d $NODE/bin ]]; then
        rc-add-path PATH "${NODE}/bin"
    else
        log "WARN: node bin dir ($NODE/bin) not found"
    fi

    if [[ -d $NODE/man ]]; then
        rc-add-path MANPATH "${NODE}/man"
    fi

    if have-builtin varsplice; then
        rc-varsplice --remove -g PATH "$HOME/.config/nvm/*"
    fi

    rc-workfile-close
fi
