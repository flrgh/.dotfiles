#!/usr/bin/env bash

readonly LOCAL=$HOME/.local/bin/bash

# this is sourced as an optional file in my main config
readonly ALACRITTY=$HOME/.config/alacritty/shell.toml

set_alacritty() {
    echo "updating alacrity ($ALACRITTY)"
    mkdir -vp "${ALACRITTY%/*}"
    cat <<EOF > "$ALACRITTY"
[terminal]
shell = "$LOCAL"
EOF
}

unset_alacritty() {
    if [[ -e $ALACRITTY ]]; then
        rm -v "$ALACRITTY"
    fi
}

if [[ -x $LOCAL ]]; then
    echo "local bash found ($LOCAL)"

    set_alacritty

else
    echo "Local bash not found"

    unset_alacritty
fi
