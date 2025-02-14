#!/usr/bin/env bash

set -euo pipefail

source ./lib/bash/facts.bash

readonly BUILD_CONFIG_ENV=./build/home/.config/env

add-export() {
    local -r name=${1:?}
    local -r value=${2:?}

    local stmt
    printf -v stmt 'export %s=%q' "$name" "$value"
    eval "$stmt"
    printf '%s\n' "$stmt" >> "$BUILD_CONFIG_ENV"

    set-var-value "$name" "$value"
    set-var-source "$name" "config-env"
    set-var-exported "$name"
}

env-init() {
    mkdir -p "$(dirname "$BUILD_CONFIG_ENV")"
}

env-reset() {
    if [[ -e $BUILD_CONFIG_ENV ]]; then
        rm "$BUILD_CONFIG_ENV"
    fi

    reset-namespace env

    env-init
}
