#!/usr/bin/env bash

set -euo pipefail

shopt -s nullglob

readonly INSTALL=$HOME/.local/lib/bash/loadables
readonly SRC=$HOME/git/flrgh/bash-builtin-extras
readonly REPO=git@github.com:flrgh/bash-builtins.git
readonly BUILTINS=(
    varsplice
    timer
    version
)

if [[ ! -d $SRC ]]; then
    git clone "$REPO" "$SRC"
fi

git -C "$SRC" pull

mkdir -p "$INSTALL"

cargo build \
    --quiet \
    --keep-going \
    --manifest-path "$SRC"/Cargo.toml \
    --release \
    --workspace

# remove old lib${name}.so and ${name}.so files
for old in "$INSTALL"/*.so; do
    rm -v "$old"
done

# remove old install dir
if [[ -d $HOME/.local/lib/bash/builtins ]]; then
    rm -rfv "$HOME/.local/lib/bash/builtins"
fi

for b in "${BUILTINS[@]}"; do
    install \
        --verbose \
        --compare \
        --no-target-directory \
        "${SRC}/target/release/lib${b}.so" \
        "${INSTALL}/${b}"
done
