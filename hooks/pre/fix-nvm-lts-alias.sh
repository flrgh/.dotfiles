#!/usr/bin/env bash

# remove the default `lts/hydrogen` alias that was mistakenly set by default
readonly ALIAS="${NVM_DIR:-$HOME/.config/nvm}/alias/default"
if grep -q lts/hydrogen "$ALIAS" &>/dev/null; then
    rm -v "$ALIAS"
fi
