#!/usr/bin/env bash

set -euo pipefail

readonly REPO=neovim/neovim
readonly NAME=nvim

readonly INSTALL_DIRS=(
    "$HOME/.local/lib/nvim"
    "$HOME/.local/share/nvim/runtime"
)

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version \
            | sed -n -r -e 's/^NVIM v?([0-9.]+).*/\1/p'
    fi
}

get-latest-version() {
    gh-helper get-releases "$REPO" \
    | jq -r '.[].tag_name' \
    | grep -vE 'stable|nightly' \
    | sort --version-sort --reverse \
    | head -1 \
    | sed -r -e 's/#v//'
}

get-asset-download-url() {
    local -r version=$1

    echo "https://github.com/neovim/neovim/releases/download/v${version}/nvim-linux64.tar.gz"
}

copy-files() {
    cp -af nvim-linux64/bin/* "$HOME/.local/bin/"
    cp -af nvim-linux64/lib/* "$HOME/.local/lib/"
    cp -af nvim-linux64/share/* "$HOME/.local/share/"
}

backup-dirs() {
    for dir in "${INSTALL_DIRS[@]}"; do
        if [[ -d $dir ]]; then
            mv -v -f "$dir" "${dir}.bak"
        fi
    done
}

restore-dirs() {
    for dir in "${INSTALL_DIRS[@]}"; do
        if [[ -d ${dir}.bak ]]; then
            mv -v -f "${dir}.bak" "$dir"
        fi
    done
}

remove-backups() {
    for dir in "${INSTALL_DIRS[@]}"; do
        dir=${dir}.bak
        if [[ -d $dir ]]; then
            rm -v -rf "$dir"
        fi
    done
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    if pidof nvim &>/dev/null; then
        echo "oops, neovim can't be updated while it's already running."
        exit 1
    fi

    cd "$(mktemp -d)"
    tar xzf "$asset"

    backup-dirs
    if copy-files; then
        remove-backups
    else
        restore-dirs
        echo "failed installing neovim!!!!"
        exit 1
    fi
}

get-binary-name() {
    echo nvim
}
