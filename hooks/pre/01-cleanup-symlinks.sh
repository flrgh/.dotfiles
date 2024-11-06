#!/usr/bin/env bash

# delete orphaned symlinks

readonly REPO_ROOT=${1:-$HOME/git/flrgh/.dotfiles}
readonly INSTALL_PATH=${2:-$HOME}
readonly FILES_D=${REPO_ROOT}/home

if [[ -L "$INSTALL_PATH/.bash" ]]; then
    echo "removing legacy ~/.bash path"
    rm -v "$INSTALL_PATH/.bash"
fi

if ! type -f -t fd &>/dev/null; then
    echo "fd not installed, exiting"
    exit 0
fi

shopt -s dotglob
shopt -s nullglob

ARGS=(
    .
    --type symlink
    --hidden
    --no-ignore
    --absolute-path
    --one-file-system
    --full-path
    --min-depth 1
)

PATHS=()

for sub in "$FILES_D"/*; do
    if [[ ! -d "$sub" ]]; then
        continue
    fi

    path=${sub/$FILES_D/$INSTALL_PATH}
    PATHS+=(--search-path "$path")
done

readonly IGNORE=(
    "GoLand-*"
    "aws-cli/v*"
    "luarocks/rocks-*"
    .config/nvm
    .cpan/build
    .git
    .local/cargo
    .local/libexec/lua-language-server
    .local/share/Steam
    .local/share/Trash
    .local/share/bash-completion/completions
    .local/share/lua/5.1
    .local/share/man/man1
    .local/share/virtualenv
    .local/state/nvim
    .local/var/log/lua-lsp
    JetBrains
    REAPER/Data
    cargo/registry
    #chromium/AutofillStates
    #chromium/Default
    flatpak
    go/misc
    go/pkg
    go/src
    go/test
    google-chrome/Default
    lib/luarocks
    lib/perl5/share/perl5
    libreoffice
    logs
    node_modules
    nvm/test
    pulse-sms/Cache
    rustup/toolchains
    site-packages
    systemtap/tapset/linux
)

for p in "${IGNORE[@]}"; do
    ARGS+=(--exclude "**/$p/")
done

EXEC=(
    --batch-size 20
    --exec-batch "$REPO_ROOT"/bin/remove-dangling-symlinks "$REPO_ROOT"
)

# $HOME itself (no recurse)
fd "${ARGS[@]}" \
    --max-depth 1 \
    --search-path "$INSTALL_PATH" \
    "${EXEC[@]}"

# $HOME sub-paths (with recurse)
fd "${ARGS[@]}" \
    "${PATHS[@]}" \
    "${EXEC[@]}"
