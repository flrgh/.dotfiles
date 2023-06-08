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

cargo install cargo-binstall

for p in "${PACKAGES[@]}"; do
    cargo binstall --no-confirm "$p" \
    || cargo install "$p"
done
