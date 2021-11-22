#!/usr/bin/env bash

set -eu

COMPLETE=(
    "pip completion --bash"
    "pip3 completion --bash"
    "hugo gen autocomplete --completionfile=%%FILE%%"
    "openstack complete --shell bash"
    "kubectl completion bash"
    "luarocks completion bash"
    "gh completion --shell bash"
)

DIR="$HOME/.local/.bash_completion.d"

echo "Initializing bash completion"

for cmd in "${COMPLETE[@]}"; do
    bin=${cmd%% *}
    if command -v "$bin" &>/dev/null; then
        echo "$bin"
        out="${DIR}/$bin"
        if [[ $cmd == *%%FILE%%* ]]; then
            ${cmd//%%FILE%%/$out}
        else
            $cmd > "$DIR/$bin"
        fi
    else
        echo "$bin (skipped)"
    fi
done
