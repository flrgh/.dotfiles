#!/usr/bin/env bash

set -eu

REPO_ROOT=$1
INSTALL_PATH=$2

CONF="$REPO_ROOT/assets/git-config"
INSTALL_DIR=$INSTALL_PATH/.config/git

ls_items() {
    git config \
        --file "$CONF" \
        --list \
        --name-only
}

set_item() {
    local -r name=$1
    echo "configurating $name"
    local val
    val=$(git config --file "$CONF" --get "$name")

    git config \
        --file "$INSTALL_DIR/config" \
        "$name" "$val"
}

mkdir -p "$INSTALL_DIR"

for item in $(ls_items); do
    set_item "$item"
done
