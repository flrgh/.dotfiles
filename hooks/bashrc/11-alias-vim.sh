#!/usr/bin/env bash

source "$REPO_ROOT"/lib/bash/generate.bash

if command -v nvm &>/dev/null; then
    bashrc-alias vim nvim
    bashrc-export-var EDITOR nvim
fi
