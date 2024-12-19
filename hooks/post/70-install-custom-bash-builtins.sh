#!/usr/bin/env bash

set -euo pipefail

readonly INSTALL=$HOME/.local/lib/bash/builtins
readonly SRC=$HOME/git/flrgh/bash-builtin-extras

mkdir -p "$INSTALL"

if [[ -d $SRC ]]; then
    pushd "$SRC"
    cargo build --release
    install \
        --target-directory "$INSTALL" \
        ./target/release/libbash_builtin_extras.so
    popd
fi
