#!/usr/bin/env bash

nvm install node
nvm install-latest-npm

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
