#!/usr/bin/env bash

set -eu

have() {
    command -v "$1" &>/dev/null
}

DIR="$HOME/.local/share/bash-completion/completions"

mkdir -p "$DIR"

declare -A COMMANDS=(
    [pip]="completion --bash"
    [pip3]="completion --bash"
    [hugo]="completion bash"
    [openstack]="complete --shell bash"
    [kubectl]="completion bash"
    [luarocks]="completion bash"
    [gh]="completion --shell bash" # github cli
    [op]="completion bash"         # 1password
    [ineed]="_bash_completion"
    [rustup]="completions bash rustup"
    [cargo]="!rustup completions bash cargo"
    [gitsign]="completion bash"
    [deck]="completion bash"
    [gh-helper]="generate-bash-completion"
    [bindgen]="--generate-shell-completions bash"
    [wasmtime]="completion bash"
)

declare -A REMOTE_FILES=(
    [busted]="https://raw.githubusercontent.com/Olivine-Labs/busted/master/completions/bash/busted.bash"
)


echo "Initializing bash completion"

for bin in "${!COMMANDS[@]}"; do
    if have "$bin"; then
        cmd="${COMMANDS[$bin]}"

        # commands that start with `!` use an alternate binary
        # included in the command string
        if [[ ${cmd#!} != "$cmd" ]]; then
            cmd=${cmd#!}
        else
            cmd="$bin $cmd"
        fi

        echo "Generating $bin completion from '$cmd'"

        out="${DIR}/$bin"

        if [[ $cmd == *%%FILE%%* ]]; then
            out=/dev/null
        fi

        if ! $cmd > "$out"; then
            echo "Failed generating completion for $bin: $?"
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
        if [[ -n ${f:-} ]]; then
            cat "$f" > "$DIR/$bin"
        else
            echo "Failed downloading completion for $bin"
        fi
    else
        echo "Skipping $bin"
    fi
done
