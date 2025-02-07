#!/usr/bin/env bash

set -euo pipefail

readonly REPO=bepaald/signalbackup-tools
readonly NAME=signalbackup-tools

is-installed() {
    binary-exists "$NAME"
}

list-available-versions() {
    gh-helper get-tag-names "$REPO" \
        | grep -v -- '-beta'
}

get-asset-download-url() {
    local -r version=$1
    echo "https://github.com/${REPO}/archive/refs/tags/${version}.tar.gz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    if ! package-info dbus-c++-devel &>/dev/null; then
        sudo dnf install -y dbus-c++-devel
    fi

    cd "$(mktemp -d)"
    tar xzf "$asset"

    cd "${NAME}-${version}"

    shopt -s failglob
    for patch in "${DRIVER_PATCH_DIR}"/*.patch; do
        patch -p0 < "$patch"
    done

    cmake -B build -DCMAKE_BUILD_TYPE=Release
    cmake --build build -j "$(nproc)"

    install \
        --verbose \
        --compare \
        --target-directory "$HOME/.local/bin" \
        "./build/${NAME}"
}
