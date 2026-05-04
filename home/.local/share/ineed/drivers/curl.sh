#!/usr/bin/env bash

set -euo pipefail

readonly REPO=curl/curl
readonly NAME=curl
readonly BIN=$HOME/.local/bin/$NAME

get-binary-name() {
    echo "$BIN"
}

is-installed() {
    [[ -x $BIN ]]
}

get-installed-version() {
    if is-installed; then
        "$BIN" --version | sed -n -r -e 's/^curl ([0-9.]+) .*/\1/p'
    fi
}

list-available-versions() {
    # tag name: curl-8_18_0
    # output: 8.18.0
    gh-helper get-tag-names "$REPO" \
    | sed -n -r -e 's/^curl-([0-9]+)_([0-9]+)_([0-9]+)/\1.\2.\3/p'
}

get-asset-download-url() {
    local -r version=$1
    echo "https://curl.se/download/curl-${version}.tar.gz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"
    tar --strip-components 1 \
        -xzf "$asset"

    local -a dirs=(
        --prefix      "$HOME/.local"
        --exec-prefix "$HOME/.local"
        --bindir      "$HOME/.local/bin"
        --libexecdir  "$HOME/.local/libexec"
        --sysconfdir  "$HOME/.local/etc"
        --runstatedir "$XDG_RUNTIME_DIR"
        --datarootdir "$XDG_DATA_HOME"
        --datadir     "$XDG_DATA_HOME"
    )

    local -a features=(
        --enable-httpsrr                  # Enable HTTPSRR support
        #--enable-ech                      # Enable ECH support
        --enable-ssls-export              # Enable SSL session export support
        #--enable-ldap                     # Enable LDAP support
        #--enable-ldaps                    # Enable LDAPS support
    )

    local -a packages=(
        --without-zsh-functions-dir  # Do not install zsh completions
        --without-fish-functions-dir # Do not install fish completions

        --without-openssl
        --with-gnutls
        --without-bearssl
        --without-mbedtls
        --without-rustls
        --without-wolfssl

        --with-zstd
        --with-libidn2
        --with-zlib
        --with-brotli
        --with-libpsl
        --with-libssh2

        --with-ngtcp2
        --with-nghttp3

        # this is broken now?
        #--with-gssapi
    )

    local triple; triple=$(gcc -dumpmachine)

    ./configure \
        --host "$triple" \
        --build "$triple" \
        "${dirs[@]}" \
        "${features[@]}" \
        "${packages[@]}"

    make -j"$(nproc)"
    make install
}
