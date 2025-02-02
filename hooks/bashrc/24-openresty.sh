#!/usr/bin/env bash

source "$REPO_ROOT"/lib/bash/generate.bash
source "$REPO_ROOT"/lib/bash/facts.bash

readonly DEST=openresty

LOCATIONS=(
    "$HOME"/.local/openresty/current
    "$HOME"/.local/openresty
    /usr/local/openresty
)

for loc in "${LOCATIONS[@]}"; do
    if have varsplice gte "0.2"; then
        bashrc-includef "$DEST" \
            'varsplice --remove -g PATH %q\n' \
            "${loc}/*"
    else
        bashrc-includef "$DEST" '__rc_rm_path PATH %q\n' "$loc/bin"
        bashrc-includef "$DEST" '__rc_rm_path PATH %q\n' "$loc/nginx/sbin"
    fi
done
