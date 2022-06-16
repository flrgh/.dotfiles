#!/usr/bin/env bash

set -eu

have() {
    command -v "$1" &>/dev/null
}

DIR="$HOME/.local/.bash_completion.d"

declare -A COMMANDS=(
    [pip]="completion --bash"
    [pip3]="completion --bash"
    [hugo]="gen autocomplete --completionfile=%%FILE%%"
    [openstack]="complete --shell bash"
    [kubectl]="completion bash"
    [luarocks]="completion bash"
    [gh]="completion --shell bash" # github cli
    [op]="completion bash"         # 1password
    [ineed]="_bash_completion"
)

declare -A REMOTE_FILES=(
    [busted]="https://raw.githubusercontent.com/Olivine-Labs/busted/master/completions/bash/busted.bash"
)


echo "Initializing bash completion"

for bin in "${!COMMANDS[@]}"; do
    if have "$bin"; then
        cmd="$bin ${COMMANDS[$bin]}"

        echo "Generating $bin completion from '$cmd'"

        out="${DIR}/$bin"

        if [[ $cmd == *%%FILE%%* ]]; then
            ${cmd//%%FILE%%/$out}
        else
            $cmd > "$DIR/$bin"
        fi
    else
        echo "Skipping $bin"
    fi
done

for bin in "${!REMOTE_FILES[@]}"; do
    if have "$bin"; then
        url=${REMOTE_FILES[$bin]}

        echo "Downloading $bin completion from $url"
        f=$(cache-get "$url" "bash-completion-${bin}")
        cat "$f" > "$DIR/$bin"
    else
        echo "Skipping $bin"
    fi
done
