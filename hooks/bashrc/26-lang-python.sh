#!/usr/bin/env bash

set -euo pipefail

source "$REPO_ROOT"/lib/bash/generate.bash

{
    PYTHONSTARTUP=$HOME/.local/.startup.py
    if [[ -f $PYTHONSTARTUP ]]; then
        bashrc-export-var PYTHONSTARTUP "$PYTHONSTARTUP"
    fi
}

{
    IPYTHONDIR="$HOME/.config/ipython"
    mkdir -p "$IPYTHONDIR"
    bashrc-export-var IPYTHONDIR "$IPYTHONDIR"
}
