#!/usr/bin/env bash

set -euo pipefail

readonly REPO=aws/aws-cli
readonly BIN_DIR=$HOME/.local/bin
readonly COMP_DIR=${BASH_COMPLETION_USER_DIR:-"$XDG_DATA_HOME"/bash-completion}/completions
readonly INSTALL_DIR=$HOME/.local/aws-cli

is-installed() {
    binary-exists aws
}

get-installed-version() {
    if is-installed; then
        aws --version \
            | awk '{print $1}' \
            | awk -F / '{print $2}'
    fi
}

get-latest-version() {
    gh-helper get-latest-tag "$REPO"
}

list-available-versions() {
    gh-helper get-tag-names "$REPO"
}

get-asset-download-url() {
    local version=$1
    echo "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${version}.zip"
}

# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-completion.html#cli-command-completion-linux
install-shell-completion() {
    local completer="$BIN_DIR/aws_completer"
    local target; target=$(realpath "$completer")

    printf 'complete -C "%s" aws\n' "$target" > "$COMP_DIR/aws"


    # declutter the bin dir
    rm "$completer"
}

cleanup-old-install() {
    local -r version=$1
    local -
    shopt -s nullglob

    echo "removing any existing assets for $version"
    for path in "$INSTALL_DIR"/*/"$version"; do
        rm -rf "${path:?}"
    done

    if [[ -L $INSTALL_DIR/current ]]; then
        rm "$INSTALL_DIR/current"
    fi
}

prune-old-installs() {
    local -
    shopt -s nullglob

    local -a found=()
    for path in "$INSTALL_DIR"/*/*; do
        if [[ -d $path && ! -L $path && $path =~ ^.*/([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
            found+=( "${BASH_REMATCH[1]}" )
        fi
    done

    local -i keep=5
    local -i prune=$(( ${#found[@]} - keep ))

    if (( prune <= 0 )); then
        return
    fi

    local tmp; tmp=$(mktemp)
    for f in "${found[@]}"; do
        echo "$f"
    done > "$tmp"

    shopt -s failglob
    while read -r line; do
        rm -rf "$INSTALL_DIR"/*"/${line:?}"
    done < <(sort -V "$tmp" | head -n "$prune")
}

install-from-asset() {
    local -r asset=$1
    local -r version=${2:?}

    cleanup-old-install "$version"
    prune-old-installs

    local tmp; tmp=$(mktemp -d)
    unzip -d "$tmp" "$asset" >/dev/null

    cd "$tmp"

    ./aws/install \
        --update \
        --install-dir "$INSTALL_DIR" \
        --bin-dir "$BIN_DIR"

    install-shell-completion
}

get-binary-name() {
  echo aws
}
