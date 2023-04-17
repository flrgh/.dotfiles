#!/usr/bin/env bash

set -euo pipefail

VERSION=$(gh-helper get-latest-release-name bazelbuild/bazel)

echo "VERSION: $VERSION"

URL=https://github.com/bazelbuild/bazel/releases/download/${VERSION}/bazel-${VERSION}-installer-linux-x86_64.sh

ASSET=$(cache-get "$URL")

echo "ASSET: $ASSET"

unzip -l "$ASSET"

unzip -p "$ASSET" bazel-complete.bash > "$HOME/.local/share/bash-completion/completions/bazel"
