#!/usr/bin/env bash

set -euo pipefail

source ./lib/bash/env.bash
source ./home/.local/lib/bash/array.bash

emit-xdg() {
    # https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
    add-export XDG_CONFIG_HOME "$HOME/.config"
    add-export XDG_DATA_HOME   "$HOME/.local/share"
    add-export XDG_STATE_HOME  "$HOME/.local/state"
    add-export XDG_CACHE_HOME  "$HOME/.cache"
}

emit-shell() {
    local bash=$HOME/.local/bin/bash
    if [[ -s $bash && -x $bash ]]; then
        add-export SHELL "$bash"

    elif bash=$(command -v bash); then
        add-export SHELL "$bash"
    fi
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
    if ! mise where go &>/dev/null; then
        add-export GOPATH       "$HOME/.local/go"
    fi

    add-export CARGO_HOME       "$HOME/.local/cargo"
    add-export MISE_CARGO_HOME  "$HOME/.local/cargo"

    add-export RUSTUP_HOME      "$HOME/.local/rustup"
    add-export MISE_RUSTUP_HOME "$HOME/.local/rustup"

    add-export MISE_PARANOID    "1"

    add-export GEM_HOME         "$HOME/.local/gems"
    add-export DOCKER_CONFIG    "$XDG_CONFIG_HOME/docker"
    add-export AZURE_CONFIG_DIR "$XDG_CONFIG_HOME/azure"
}

emit-ls-colors() {
    if [[ ! -e build/LS_COLORS ]]; then
        echo "error: build/LS_COLORS is missing"
        return 1
    fi
    local colors; colors=$(< build/LS_COLORS)
    add-export LS_COLORS "${colors:?}"
}

emit-pkg-config() {
    local -a paths=(
        "$HOME/.local/lib/pkgconfig"

        # bash-completion puts its pkg-config stuff in ~/.local/share/pkgconfig,
        # which is an outlier, but I don't care to do anything about that right now
        "$HOME/.local/share/pkgconfig"
    )

    add-export PKG_CONFIG_PATH "$(array-join ':' "${paths[@]}")"
}

emit-bitwarden-secrets-manager() {
    local conf=${XDG_CONFIG_HOME}/bws/config
    mkdir -p "${conf%/*}"

    local -r profile=main

    add-export BWS_CONFIG_FILE "$conf"
    add-export BWS_PROFILE "$profile"

    if command -v bws &>/dev/null; then
        local -a args=(
            --config-file "$conf"
            --profile "$profile"
            config
        )

        bws "${args[@]}" \
            state-dir "${XDG_STATE_HOME}/bws"

        bws "${args[@]}" \
            server-api "https://api.bitwarden.com"

        bws "${args[@]}" \
            server-identity "https://identity.bitwarden.com"
    fi

    if [[ -e ${XDG_CONFIG_HOME}/bws/state ]]; then
        rm -rf "${XDG_CONFIG_HOME}/bws/state"
    fi
}

main() {
    env-reset

    : "${HOME:?}"

    emit-xdg
    emit-shell
    emit-common
    emit-locale
    emit-editor
    emit-app-config
    emit-ls-colors
    emit-pkg-config
    emit-bitwarden-secrets-manager

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
