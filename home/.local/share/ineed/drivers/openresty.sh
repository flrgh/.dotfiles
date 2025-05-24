#!/usr/bin/env bash

set -euo pipefail

readonly REPO=openresty/openresty
readonly NAME=openresty
readonly INSTALL_ROOT=$HOME/.local/${NAME}
readonly CURRENT_INSTALL=${INSTALL_ROOT}/current

is-installed() {
    binary-exists "$NAME"
}

get-installed-version() {
    if is-installed; then
        :
    fi
}

list-available-versions() {
    gh-helper get-tag-names "$REPO"
}

get-latest-version() {
    list-available-versions | sort -Vr | head -1
}

get-asset-download-url() {
    local -r version=$1
    echo "https://openresty.org/download/openresty-${version}.tar.gz"
}

clean-install-root() {
    shopt -s extglob
    shopt -s nullglob

    local elem
    for elem in "$INSTALL_ROOT"/*; do
        local name=${elem##*/}

        # if it looks like a 4 digit OpenResty version number, continue
        if [[ $name =~ ^[0-9]+\.[0-9]+\.[0-9]\.[0-9]+$ ]]; then
            continue

        elif [[ $elem == "$CURRENT_INSTALL" || $name == current ]]; then
            continue
        fi

        rm -rfv "$elem"
    done
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"
    tar -xzf "$asset"
    cd "openresty-${version}"

    clean-install-root

    local -r prefix=${INSTALL_ROOT}/${version}
    mkdir -p "$prefix"

    local -a flags=(
        --prefix="${prefix}"

    #   --sbin-path=PATH                   set nginx binary pathname
    #   --modules-path=PATH                set modules path
    #   --conf-path=PATH                   set nginx.conf pathname
    #   --error-log-path=PATH              set error log pathname
    #   --pid-path=PATH                    set nginx.pid pathname
    #   --lock-path=PATH                   set nginx.lock pathname

        --with-threads
        --with-file-aio
        --with-pcre
        --with-pcre-jit

        --with-http_gunzip_module
        --with-http_realip_module
        --with-http_ssl_module
        --with-http_v2_module
        --with-http_v3_module

        --without-http_encrypted_session_module
        --without-http_fastcgi_module
        --without-http_form_input_module
        --without-http_grpc_module
        --without-http_memc_module
        --without-http_memcached_module
        --without-http_rds_csv_module
        --without-http_rds_json_module
        --without-http_scgi_module
        --without-http_srcache_module
        --without-http_uwsgi_module
        --without-http_xss_module

        --without-mail_pop3_module
        --without-mail_imap_module
        --without-mail_smtp_module

        --with-stream
        --with-stream_realip_module
        --with-stream_ssl_module
        --with-stream_ssl_preread_module
    )

    ./configure "${flags[@]}"
    make -j"$(nproc)" install

    ln -nsfv "$version" "$CURRENT_INSTALL"

    if [[ -e "${prefix}"/nginx/sbin/nginx.old ]]; then
        rm "${prefix}"/nginx/sbin/nginx.old
    fi

    local -r vbin=$HOME/.local/vbin/${NAME}/${version}
    rm -rf "$vbin"
    mkdir -p "$vbin"

    ln \
        --verbose \
        --force \
        --symbolic \
        --target-directory "$vbin" \
        "${prefix}"/bin/* \
        "${prefix}"/nginx/sbin/*

    vbin-link "$NAME" "$version"
}
