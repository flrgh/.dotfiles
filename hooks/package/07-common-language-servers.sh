#!/usr/bin/env bash

for f in "$HOME/.local/libexec/install/lsp/"*; do
    "$f" || {
        echo "failure: $(basename $f)"
        exit 1
    }
done
