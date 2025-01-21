#!/usr/bin/env bash

set -euo pipefail

readonly INSTALL=$HOME/.local/lib/bash/builtins
readonly SRC=$HOME/git/flrgh/bash-builtin-extras
readonly REPO=git@github.com:flrgh/bash-builtins.git

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

install \
    --verbose \
    --compare \
    -D \
    --target-directory "$INSTALL" \
    "$SRC"/target/release/libbash_builtin_extras.so \
    "$SRC"/target/release/libvarsplice.so \
    "$SRC"/target/release/libtimer.so
