#!/usr/bin/env bash

set -eu

echo "Installing vim plugins"
vim --not-a-term +BundleInstall +qall
