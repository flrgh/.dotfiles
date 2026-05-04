#!/usr/bin/env bash

set -euo pipefail

readonly REPO=ngtcp2/nghttp3
readonly NAME=nghttp3
readonly PREFIX=$HOME/.local
readonly PKGCONFIG=$PREFIX/lib/pkgconfig/libnghttp3.pc

get-binary-name() {
    # library-only — no binary
    echo "$PKGCONFIG"
}

is-installed() {
    [[ -f $PKGCONFIG ]]
}

get-installed-version() {
    if is-installed; then
        PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig pkg-config --modversion libnghttp3
    fi
}

list-available-versions() {
    gh-helper get-tag-names "$REPO" \
    | sed -n -r -e 's/^v([0-9]+\.[0-9]+\.[0-9]+)$/\1/p'
}

get-asset-download-url() {
    local -r version=$1
    echo "https://github.com/$REPO/releases/download/v${version}/nghttp3-${version}.tar.xz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"
    tar --strip-components 1 -xJf "$asset"

    ./configure \
        --prefix="$PREFIX" \
        --enable-lib-only \
        --disable-static

    make -j"$(nproc)"
    make install
}
