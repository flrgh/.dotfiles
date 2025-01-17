#!/usr/bin/env bash

source "$REPO_ROOT"/lib/bash/generate.bash

if bashrc-command-exists bat; then
    bashrc-export-var MANPAGER "sh -c 'col -bx | bat -l man -p'"
    bashrc-export-var MANROFFOPT "-c"
fi
