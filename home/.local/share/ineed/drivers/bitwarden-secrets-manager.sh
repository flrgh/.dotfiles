#!/usr/bin/env bash

set -euo pipefail

readonly REPO=bitwarden/sdk-sm
readonly BASE_URL=https://github.com/${REPO}/releases/download
readonly NAME=bws

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version
    fi
}

get-latest-version() {
    gh-helper get-releases "$REPO" \
        | jq -r '.[].tag_name | select(test("^bws"))' \
        | sed -re 's/^bws-(cli-)?v//' \
        | sort --version-sort --reverse \
        | head -1
}

get-asset-download-url() {
    local -r version=$1
    # https://github.com/bitwarden/sdk-sm/releases/download/bws-v1.0.0/bws-x86_64-unknown-linux-gnu-1.0.0.zip
    echo "${BASE_URL}/bws-v${version}/bws-x86_64-unknown-linux-gnu-${version}.zip"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    echo "Fetching checksum for bitwarden secrets manager $version"
    # https://github.com/bitwarden/sdk-sm/releases/download/bws-v1.0.0/bws-sha256-checksums-1.0.0.txt
    local sum_file
    sum_file=$(cache-get "${BASE_URL}/bws-v${version}/bws-sha256-checksums-${version}.txt")

    cat "$sum_file"
    local checksum
    checksum=$(awk '/bws-x86_64-unknown-linux-gnu/ {print $1}' "$sum_file")
    echo "checksum: ($checksum)"

    echo "Validating download checksum"

    printf "%q %q\n" "$checksum" "$asset" \
        | sha256sum --check --strict

    local tmp; tmp=$(mktemp -d)
    cd "$tmp"
    unzip "$asset"
    mv -f -v "$NAME" "$HOME/.local/bin/${NAME}"
}
