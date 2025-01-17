#!/usr/bin/env bash

source "$REPO_ROOT"/lib/bash/generate.bash

if command -v lsd &>/dev/null; then
    bashrc-alias ls "lsd -l"
fi
