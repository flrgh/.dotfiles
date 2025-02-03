#!/usr/bin/env bash

set -euo pipefail

readonly OUT=./build/home/.config/env

add-export() {
    local stmt
    printf -v stmt 'export %s=%q' "$1" "${2:?}"
    eval "$stmt"
    printf '%s\n' "$stmt" >> "$OUT"
}

main() {
    mkdir -p "$(dirname "$OUT")"
    if [[ -e $OUT ]]; then
        rm "$OUT"
    fi

    add-export HOME            "${HOME:?}"
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
