#!/usr/bin/env bash

source ./lib/bash/generate.bash

LOCATIONS=(
    "$HOME"/.local/openresty/current
    "$HOME"/.local/openresty
    /usr/local/openresty
)

if have-builtin varsplice gte "0.2"; then
    for loc in "${LOCATIONS[@]}"; do
        rc-varsplice --remove -g PATH "${loc}/*"
    done
else
    for loc in "${LOCATIONS[@]}"; do
        rc-rm-path PATH "$loc/bin"
        rc-rm-path PATH "$loc/nginx/sbin"
    done
fi
