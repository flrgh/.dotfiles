#!/usr/bin/env bash

set -euo pipefail

source ./lib/bash/facts.bash

readonly OUT=./build/home/.config/env

add-export() {
    local -r name=${1:?}
    local -r value=${2:?}

    local stmt
    printf -v stmt 'export %s=%q' "$name" "$value"
    eval "$stmt"
    printf '%s\n' "$stmt" >> "$OUT"

    set-var-value "$name" "$value"
    set-var-source "$name" "config-env"
    set-var-exported "$name"
}

main() {
    mkdir -p "$(dirname "$OUT")"
    if [[ -e $OUT ]]; then
        rm "$OUT"
    fi

    init-facts

    : "${HOME:?}"

    add-export CONFIG_HOME     "$HOME/.config"
    add-export CACHE_DIR       "$HOME/.cache"

    # https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
    add-export XDG_CONFIG_HOME "$CONFIG_HOME"
    add-export XDG_DATA_HOME   "$HOME/.local/share"
    add-export XDG_STATE_HOME  "$HOME/.local/state"
    add-export XDG_CACHE_HOME  "$CACHE_DIR"

    add-export LC_ALL          "en_US.UTF-8"
    add-export LANG            "en_US.UTF-8"
    add-export EDITOR          "vim"

    add-export GOPATH           "$HOME/.local/go"
    add-export CARGO_HOME       "$HOME/.local/cargo"
    add-export RUSTUP_HOME      "$HOME/.local/rustup"
    add-export GEM_HOME         "$HOME/.local/gems"
    add-export DOCKER_CONFIG    "${CONFIG_HOME:?}/docker"
    add-export AZURE_CONFIG_DIR "${CONFIG_HOME:?}/azure"

    for f in ./env/*; do
        cat "$f" >> "$OUT"
    done

    if command -v shfmt &>/dev/null; then
        shfmt \
            --write \
            --language-dialect posix \
            --simplify \
            --indent 2 \
            --binary-next-line \
            "$OUT"

    else
        bash -n "$OUT"
    fi

    echo '# vim: set ft=sh:' >> "$OUT"
}

main "$@"
