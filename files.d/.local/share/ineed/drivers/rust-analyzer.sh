#!/usr/bin/env bash

# rust language server

# https://rust-analyzer.github.io/


readonly REPO=rust-analyzer/rust-analyzer
readonly NAME=rust-analyzer


# helpers
#
# * binary-exists

list-available-versions() {
    gh-helper get-releases "$REPO" \
    | jq -r '.[].name'
}


get-latest-version() {
    gh-helper get-latest-release-name "$REPO"
}


get-installed-version() {
    "$NAME" --version | awk '{print $4}' | tr -d '()'
}

is-installed() {
    binary-exists "$NAME"
}

get-asset-download-url() {
    local version=$1

    echo "https://github.com/rust-lang/rust-analyzer/releases/download/${version}/rust-analyzer-x86_64-unknown-linux-gnu.gz"
}

install-from-asset() {
    local asset=$1
    local version=$2

    gunzip -c \
        < "$asset" \
        > "$HOME"/.local/bin/"$NAME"

    chmod +x "$HOME"/.local/bin/"$NAME"
}
