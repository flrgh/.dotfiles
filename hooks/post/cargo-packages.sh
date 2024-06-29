#!/usr/bin/env bash

set -euo pipefail

readonly PACKAGES=(
    alacritty      # terminal emulator
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

for p in "${PACKAGES[@]}"; do
    cargo binstall --no-confirm "$p" \
    || cargo install "$p"
done
