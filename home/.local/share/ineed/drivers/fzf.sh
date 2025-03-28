#!/usr/bin/env bash

set -euo pipefail

readonly NAME=fzf
readonly REPO=junegunn/fzf
readonly BIN="$HOME/.local/bin/$NAME"

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        local v; v=$("$NAME" --version)
        echo "${v%% *}"
    fi
}

get-latest-version() {
    gh-helper get-latest-tag "$REPO"
}

list-available-versions() {
    gh-helper get-release-names "$REPO"
}

get-asset-download-url() {
    local -r version=$1

    # https://github.com/junegunn/fzf/releases/download/v0.54.3/fzf-0.54.3-linux_amd64.tar.gz
    echo "https://github.com/${REPO}/releases/download/v${version}/fzf-${version}-linux_amd64.tar.gz"
}


install-man-page() {
    local dir="$HOME"/.local/share/man/man1
    mkdir -p "$dir"

    # -R tells `man` to re-encode the input rather than formatting it for display
    MANOPT='-R' "$BIN" --man > "$dir"/fzf.1
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"

    tar -xzf "$asset"
    vbin-install fzf "$version" "$PWD/fzf"

    install-man-page
}
