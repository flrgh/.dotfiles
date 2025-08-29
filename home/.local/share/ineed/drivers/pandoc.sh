#!/usr/bin/env bash

set -euo pipefail

readonly NAME=pandoc
readonly REPO=jgm/pandoc

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version | awk '/^pandoc/ {print $2}'
    fi
}

list-available-versions() {
    gh-helper get-stable-releases "$REPO" \
    | jq -r '.[].tag_name'
}

get-asset-download-url() {
    local -r version=$1
    #https://github.com/jgm/pandoc/releases/download/3.6.3/pandoc-3.6.3-linux-amd64.tar.gz
    echo "https://github.com/${REPO}/releases/download/${version}/pandoc-${version}-linux-amd64.tar.gz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"

    tar --extract \
        --strip-components 1 \
        --file "$asset"


    shopt -s nullglob
    rm -vf "$HOME"/.local/share/man/man*/pandoc*

    shopt -s failglob
    shopt -s globstar
    for elem in ./**; do
        if [[ ! -f $elem ]]; then
            continue
        fi

        local dest=$HOME/.local/${elem#./}

        # install adds the execute bit by default, so we gotta branch on
        # bin vs not bin
        if [[ $dest == */bin/* ]]; then
            install \
                --verbose \
                --preserve-timestamps \
                --no-target-directory \
                "$elem" \
                "$dest"
        else
            install \
                --mode 0664 \
                --verbose \
                --preserve-timestamps \
                --no-target-directory \
                "$elem" \
                "$dest"
        fi
    done
}
