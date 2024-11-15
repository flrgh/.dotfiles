#!/usr/bin/env bash

set -euo pipefail

export CARGO_HOME=${CARGO_HOME:-$HOME/.local/cargo}
export RUSTUP_HOME=${RUSTUP_HOME:-$HOME/.local/rustup}
export PATH="$CARGO_HOME/bin:$PATH"

mkdir -p "$CARGO_HOME" "$RUSTUP_HOME"

if [[ ! -x $CARGO_HOME/bin/rustup ]]; then
    echo "rustup not found, installing..."

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- \
            -y \
            --no-modify-path \
            --default-host x86_64-unknown-linux-gnu
fi

# housekeeping
rustup self update
rustup self upgrade-data

rustup toolchain install \
    stable \
    nightly

# install commonly needed targets
rustup target add \
    x86_64-unknown-linux-gnu \
    wasm32-unknown-unknown \
    wasm32-wasip1
    # aarch64-apple-darwin
    # aarch64-unknown-linux-gnu
    # aarch64-unknown-linux-musl
    # wasm32-wasi
    # x86_64-apple-darwin
    # x86_64-unknown-linux-musl

# FIXME: I want to use the nightly toolchain for rust-analyzer, clippy, and the
# like, but LSP diagnostics are not working when I do this
rustup component add --toolchain stable \
    cargo \
    clippy \
    rust-analyzer \
    rust-docs \
    rust-std \
    rustc \
    rustfmt

rustup update
