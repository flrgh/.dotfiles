#!/usr/bin/env bash

set -euo pipefail

readonly REPO=neovim/neovim
readonly NAME=nvim
readonly BASE_URL="https://github.com/neovim/neovim/releases/download"
readonly PREFIX=$HOME/.local

readonly INSTALL_DIRS=(
    "$PREFIX/lib/nvim"
    "$PREFIX/share/nvim/runtime"
)

get-platform-label() {
    local -r version=${1:?}

    local platform

    # see https://github.com/neovim/neovim/releases/tag/v0.10.4
    if version-compare "$version" gte "0.10.4"; then
        platform=nvim-linux-x86_64
    else
        platform=nvim-linux64
    fi

    echo "$platform"
}


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

    echo "${BASE_URL}/v${version}/$(get-platform-label "$version").tar.gz"
}

copy-files() {
    local -r version=${1:?}
    local label; label=$(get-platform-label "$version")

    for dir in bin lib share; do
        cp -af "${label}/${dir}/"* "${PREFIX}/${dir}/"
    done
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
    if copy-files "$version"; then
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
