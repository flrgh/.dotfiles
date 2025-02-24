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
    gh-helper get-release-names "$REPO"
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
        --enable-optimize                 # Enable compiler optimizations
        --enable-httpsrr                  # Enable HTTPSRR support
        #--enable-ech                      # Enable ECH support
        --enable-ssls-export              # Enable SSL session export support
        --enable-http                     # Enable HTTP support
        --enable-ftp                      # Enable FTP support
        --enable-file                     # Enable FILE support
        --enable-ipfs                     # Enable IPFS support
        #--enable-ldap                     # Enable LDAP support
        #--enable-ldaps                    # Enable LDAPS support
        --enable-rtsp                     # Enable RTSP support
        --enable-proxy                    # Enable proxy support
        --enable-dict                     # Enable DICT support
        --enable-telnet                   # Enable TELNET support
        --enable-tftp                     # Enable TFTP support
        --enable-pop3                     # Enable POP3 support
        --enable-imap                     # Enable IMAP support
        --enable-smb                      # Enable SMB/CIFS support
        --enable-smtp                     # Enable SMTP support
        --enable-gopher                   # Enable Gopher support
        --enable-mqtt                     # Enable MQTT support
        --enable-manual                   # Enable built-in manual
        --enable-docs                     # Enable documentation
        --enable-libcurl-option           # Enable --libcurl C code generation support
        --enable-ipv6                     # Enable IPv6 (with IPv4) support
        --enable-openssl-auto-load-config # Enable automatic loading of OpenSSL configuration
        --disable-ca-search               # Disable unsafe CA bundle search in PATH on Windows
        --enable-ca-search-safe           # Enable safe CA bundle search
        --disable-sspi                    # Disable SSPI
        --enable-basic-auth               # Enable basic authentication (default)
        --enable-bearer-auth              # Enable bearer authentication (default)
        --enable-digest-auth              # Enable digest authentication (default)
        --enable-kerberos-auth            # Enable kerberos authentication (default)
        --enable-negotiate-auth           # Enable negotiate authentication (default)
        --enable-aws                      # Enable AWS sig support (default)
        --enable-ntlm                     # Enable NTLM support
        --enable-tls-srp                  # Enable TLS-SRP authentication
        --enable-unix-sockets             # Enable Unix domain sockets
        --enable-cookies                  # Enable cookies support
        --enable-socketpair               # Enable socketpair support
        --enable-http-auth                # Enable HTTP authentication support
        --enable-doh                      # Enable DoH support
        --enable-mime                     # Enable mime API support
        --enable-bindlocal                # Enable local binding support
        --enable-form-api                 # Enable form API support
        --enable-dateparse                # Enable date parsing
        --enable-netrc                    # Enable netrc parsing
        --enable-progress-meter           # Enable progress-meter
        --enable-sha512-256               # Enable SHA-512/256 hash algorithm (default)
        --enable-dnsshuffle               # Enable DNS shuffling
        --enable-alt-svc                  # Enable alt-svc support
        --enable-headers-api              # Enable headers-api support
        --enable-hsts                     # Enable HSTS support
        --enable-websockets               # Enable WebSockets support
    )

    local -a packages=(
        --without-schannel           # enable Windows native SSL/TLS
        --without-secure-transport   # enable Apple OS native SSL/TLS
        --without-amissl             # enable Amiga native SSL/TLS (AmiSSL)
        --without-winidn             # disable Windows native IDN
        --without-apple-idn          # Disable AppleIDN
        --without-zsh-functions-dir  # Do not install zsh completions
        --without-fish-functions-dir # Do not install fish completions

        --with-openssl
        --without-bearssl
        --without-gnutls
        --without-mbedtls
        --without-rustls
        --without-secure-transport
        --without-wolfssl

        --with-zstd
        --with-libidn2
        --with-zlib
        --with-brotli
        --with-libpsl
        --with-libssh2
        --with-gssapi
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
