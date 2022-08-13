#!/usr/bin/env bash
# shellcheck disable=SC2034

readonly REPO=
readonly NAME=


# helpers
#
# * binary-exists

_nyi() {
    echo "This function is NYI"
    return 127
}

list-available-versions() {
    _nyi
}

get-latest-version() {
    _nyi
}


get-installed-version() {
    _nyi
}

is-installed() {
    _nyi
}

get-asset-download-url() {
    local version=$1

    _nyi
}

install-from-asset() {
    local asset=$1
    local version=$2

    _nyi
}
