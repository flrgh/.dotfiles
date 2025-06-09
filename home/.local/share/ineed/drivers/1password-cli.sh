#!/usr/bin/env bash

# SEE ALSO:
# https://github.com/1Password/install-cli-action/blob/693863cbc91b8890978d1d693ca24026a1a01763/install-cli.sh

set -euo pipefail

readonly META_URL="https://app-updates.agilebits.com/product_history/CLI2"

readonly NAME=op

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        "$NAME" --version
    fi
}

list-available-versions() {
    local fname; fname=$(cache-get "$META_URL" 1password-cli.meta.html 2>/dev/null)
    sed -n -r \
        -e 's#.*href=.*v([0-9]+\.[0-9]+\.[0-9]+)/op_linux_amd64.*#\1#p' \
        < "$fname" \
    | sort -Vr
}


get-latest-version() {
    list-available-versions | head -1
}


get-asset-download-url() {
    local -r version=$1
    echo "https://cache.agilebits.com/dist/1P/op2/pkg/v${version}/op_linux_amd64_v${version}.zip"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    local tmp; tmp=$(mktemp -d)
    cd "$tmp"

    unzip "$asset"
    vbin-install op "$version" "$PWD/op"

    "$NAME" --version
}
