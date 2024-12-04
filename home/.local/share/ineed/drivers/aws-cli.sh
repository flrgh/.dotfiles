#!/usr/bin/env bash

set -euo pipefail

readonly REPO=aws/aws-cli
readonly BIN_DIR=$HOME/.local/bin
readonly COMP_DIR=${BASH_COMPLETION_USER_DIR:-"$XDG_DATA_HOME"/bash-completion}/completions

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

install-from-asset() {
    local -r asset=$1

    local tmp; tmp=$(mktemp -d)

    unzip -d "$tmp" "$asset" >/dev/null

    cd "$tmp"

    ./aws/install \
        --update \
        --install-dir "$HOME/.local/aws-cli" \
        --bin-dir "$BIN_DIR"

    install-shell-completion
}

get-binary-name() {
  echo aws
}
