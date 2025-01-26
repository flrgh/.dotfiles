#!/usr/bin/env bash
# shellcheck disable=SC2034

source "$INEED_ROOT/lib.sh"

REPO=
NAME=


_nyi() {
    echo "NYI" >&2
    return 127
}

base-driver::list-available-versions() {
    _nyi
}

base-driver::get-latest-version() {
    list-available-versions | latest-version
}

base-driver::get-installed-version() {
    _nyi
}

base-driver::get-binary-name() {
    _nyi
}

base-driver::is-installed() {
    _nyi
}

base-driver::get-asset-download-url() {
    local version=$1

    _nyi
}

base-driver::install-from-asset() {
    local asset=$1
    local version=$2

    _nyi
}
