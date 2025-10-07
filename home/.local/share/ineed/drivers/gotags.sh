#!/usr/bin/env bash
# shellcheck disable=SC2034

readonly REPO=jstemmer/gotags
readonly NAME=gotags

list-available-versions() {
    gh-helper get-tag-names "$REPO" \
        | sed -n -r -e 's/.*v([0-9]+\.[0-9]+\.[0-9]+).*/\1/p'
}

get-latest-version() {
    list-available-versions \
        | sort -V \
        | tail -1
}

get-installed-version() {
    "$NAME" -v \
        | sed -n -r -e 's/.*v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/p'
}

get-binary-name() {
    echo "$NAME"
}

is-installed() {
    return 0
}

get-asset-download-url() {
    local version=$1
    echo "https://github.com/jstemmer/gotags/archive/refs/tags/v${version}.tar.gz"
}

install-from-asset() {
    local _asset=$1
    local version=$2

    local -r url="github.com/${REPO}@v${version}"

    local go
    if go=$(mise which go); then
        "$go" install "$url"
        mise reshim
    else
        go install "$url"
    fi
}
