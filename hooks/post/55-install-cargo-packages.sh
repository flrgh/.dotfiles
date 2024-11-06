#!/usr/bin/env bash

set -euo pipefail

export CARGO_HOME=${CARGO_HOME:-$HOME/.local/cargo}
export RUSTUP_HOME=${RUSTUP_HOME:-$HOME/.local/rustup}
export PATH="$CARGO_HOME/bin:$PATH"

mkdir -p "$CARGO_HOME" "$RUSTUP_HOME"

# I am an island; don't use system rustup/cargo
if [[ ! -x $CARGO_HOME/bin/cargo ]]; then
    if [[ ! -x $CARGO_HOME/bin/rustup ]]; then
        echo "rustup not found, installing..."

        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
            | sh -s -- \
                -y \
                --no-modify-path \
                --default-host x86_64-unknown-linux-gnu
    fi

    echo "cargo not found, installing..."
    rustup component add cargo
fi

# housekeeping
rustup self update
rustup self upgrade-data
rustup update

# install commonly needed targets
readonly TARGETS=(
    #aarch64-apple-darwin
    #aarch64-unknown-linux-gnu
    #aarch64-unknown-linux-musl
    wasm32-unknown-unknown
    #wasm32-wasi
    wasm32-wasip1
    #x86_64-apple-darwin
    x86_64-unknown-linux-gnu
    #x86_64-unknown-linux-musl
)
rustup target add "${TARGETS[@]}"

readonly PACKAGES=(
    alacritty      # terminal emulator
    bindgen-cli
    btm            # nifty system monitor (top => btm)
    cargo-bloat
    cargo-cache
    cargo-dist
    cargo-edit
    cargo-expand
    cargo-modules
    cargo-release
    cargo-update
    cross          # cargo cross-compilation helper
    inferno        # rust port of flamegraph.pl
    lsd            # fancier version of `ls`
    ripgrep
    stylua
    wasm-pack
    worker-build   # for cloudflare workers
)

if [[ -e ~/.config/github/helper-access-token ]]; then
    source ~/.config/github/helper-access-token
    export GITHUB_TOKEN
fi

if command -v cargo-binstall &>/dev/null; then
    echo "checking for updates to cargo-binstall"
    cargo binstall \
        --no-confirm \
        --only-signed \
        cargo-binstall

else
    echo "installing cargo-binstall from source"
    cargo install cargo-binstall
fi

cargo binstall \
    --no-confirm \
    --continue-on-failure \
    "${PACKAGES[@]}"
