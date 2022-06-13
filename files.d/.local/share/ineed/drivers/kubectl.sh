#!/usr/bin/env bash

set -euo pipefail

readonly INSTALL="$HOME/.local/bin/kubectl"

is-installed() {
    binary-exists kubectl
}

get-installed-version() {
    if is-installed; then
        kubectl version \
            --client=true \
            --output json \
            2>/dev/null \
        | jq -r '.clientVersion.gitVersion' \
        | tr -d 'v'
    fi
}

get-latest-version() {
    curl -f --silent -L https://dl.k8s.io/release/stable.txt \
    | tr -d 'v'
}

get-asset-download-url() {
    local -r version=$1

    echo "https://dl.k8s.io/release/$version/bin/linux/amd64/kubectl"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2


    #SUM=$(cache-get \
    #    "https://dl.k8s.io/$VERSION/bin/linux/amd64/kubectl.sha256" \
    #    "${FNAME}.sha256"
    #)

    #echo "$(< "$SUM")" "$F" | sha256sum --check


    cp -v "$asset" "$INSTALL"
    chmod -v +x "$INSTALL"
}
