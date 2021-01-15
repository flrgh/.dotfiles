#!/usr/bin/env bash

set -euo pipefail

for f in "$HOME/.local/libexec/install/lsp/"*; do
    "$f"
done
