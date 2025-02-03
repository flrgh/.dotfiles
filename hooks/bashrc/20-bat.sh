#!/usr/bin/env bash

source ./lib/bash/generate.bash

if rc-command-exists bat; then
    rc-export MANPAGER "sh -c 'col -bx | bat -l man -p'"
    rc-export MANROFFOPT "-c"
fi
