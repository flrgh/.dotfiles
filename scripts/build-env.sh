#!/usr/bin/env bash

set -euo pipefail

source ./lib/bash/env.bash

emit-xdg() {
    # https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
    add-export XDG_CONFIG_HOME "$HOME/.config"
    add-export XDG_DATA_HOME   "$HOME/.local/share"
    add-export XDG_STATE_HOME  "$HOME/.local/state"
    add-export XDG_CACHE_HOME  "$HOME/.cache"
}

emit-common() {
    add-export CONFIG_HOME "$XDG_CONFIG_HOME"
    add-export CACHE_DIR   "$XDG_CACHE_HOME"
}

emit-locale() {
    add-export LC_ALL "en_US.UTF-8"
    add-export LANG   "en_US.UTF-8"
}

emit-editor() {
    if command -v nvim &>/dev/null; then
        add-export EDITOR "nvim"
    else
        add-export EDITOR "vim"
    fi
}

emit-app-config() {
    add-export GOPATH           "$HOME/.local/go"
    add-export CARGO_HOME       "$HOME/.local/cargo"
    add-export RUSTUP_HOME      "$HOME/.local/rustup"
    add-export GEM_HOME         "$HOME/.local/gems"
    add-export DOCKER_CONFIG    "$XDG_CONFIG_HOME/docker"
    add-export AZURE_CONFIG_DIR "$XDG_CONFIG_HOME/azure"
}

emit-ls-colors() {
    if ! command -v dircolors &>/dev/null; then
        return
    fi

    local -r url=https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.256dark
    local dl; dl=$(cache-get "$url")

    # dircolors emits an expression for us to eval
    local colors
    colors=$(dircolors "$dl")
    unset LS_COLORS
    eval "$colors"
    add-export LS_COLORS "${LS_COLORS:?}"
}

main() {
    env-reset

    : "${HOME:?}"

    emit-xdg
    emit-common
    emit-locale
    emit-editor
    emit-app-config
    emit-ls-colors

    if command -v shfmt &>/dev/null; then
        shfmt \
            --write \
            --language-dialect posix \
            --simplify \
            --indent 2 \
            --binary-next-line \
            "$BUILD_CONFIG_ENV"

    else
        bash -n "$BUILD_CONFIG_ENV"
    fi

    echo '# vim: set ft=sh:' >> "$BUILD_CONFIG_ENV"
}

main "$@"
