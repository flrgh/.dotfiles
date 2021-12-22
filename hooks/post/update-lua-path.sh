#!/usr/bin/env bash

if command -v luarocks &>/dev/null; then
    echo "Creating bash env file for lua path+cpath"

    mkdir -p "$HOME/.local/.bash"

    echo '# auto-generated; do not edit by hand' \
        > "$HOME/.local/.bash/lua-path.sh"

    luarocks path --no-bin \
        | tee -a "$HOME/.local/.bash/lua-path.sh"
fi
