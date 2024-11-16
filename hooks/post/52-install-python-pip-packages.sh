#!/usr/bin/env bash

if ! type -p pip &>/dev/null; then
    echo "pip is not installed, exiting"
    exit
fi

readonly PACKAGES=(
    compiledb  # generate compile_commands.json for clangd
)

pip install --user --upgrade "${PACKAGES[@]}"
