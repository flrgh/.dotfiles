#!/usr/bin/env bash

if ! command -v gitsign &>/dev/null; then
    echo "Installing gitsign CLI"
    go install github.com/sigstore/gitsign@latest
fi

if ! command -v gitsign-credential-cache &>/dev/null; then
    echo "Installing gitsign credential cache"
    go install github.com/sigstore/gitsign/cmd/gitsign-credential-cache@latest
fi

systemctl --user daemon-reload
systemctl --user enable --now gitsign-credential-cache.socket
