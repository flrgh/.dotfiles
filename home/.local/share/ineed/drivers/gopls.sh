#!/usr/bin/env bash
# shellcheck disable=SC2034

readonly REPO=golang/tools
readonly NAME=gopls

list-available-versions() {
    gh-helper get-stable-releases "$REPO" \
        | jq -r '.[].tag_name' \
        | sed -n -r -e 's#^gopls/v(.+)#\1#p'
}

get-latest-version() {
    list-available-versions \
        | sort -V \
        | tail -1
}

get-installed-version() {
    "$NAME" version \
        | sed -n -r -e 's/.*v([0-9]+\.[0-9]+\.[0-9]+).*/\1/p'
}

get-binary-name() {
    echo "$NAME"
}

is-installed() {
    return 0
}

get-asset-download-url() {
    local version=$1
    echo "https://github.com/golang/tools/archive/refs/tags/gopls/v${version}.tar.gz"
}

install-from-asset() {
    local _asset=$1
    local version=$2
    local -r url="golang.org/x/tools/gopls@v${version}"

    "$HOME/.local/libexec/golang-install-bin" "$url"
}
