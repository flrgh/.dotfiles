#!/usr/bin/env bash

if ! command -v mise &>/dev/null; then
    echo "WARN: mise is not installed, so we can't use npm"
    exit
fi

npm() {
    mise exec node -- npm "$@"
}

readonly PACKAGES=(
    # language servers
    awk-language-server
    bash-language-server
    dockerfile-language-server-nodejs
    pyright
    sql-language-server
    typescript-language-server
    vscode-json-languageserver
    yaml-language-server
)

npm install -g "${PACKAGES[@]}"
