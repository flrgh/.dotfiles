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
    .cpan/build
    .git
    .local/share/gnome-shell
    .local/share/nvim
    .local/share/virtualenv
    JetBrains
    REAPER/Data
    cargo/registry
    flatpak
    go/misc
    go/pkg
    go/src
    go/test
    google-chrome/Default
    lib/luarocks
    lib/perl5/share/perl5
    logs
    lua-language-server/3rd
    lua-language-server/meta/3rd
    node_modules
    pulse-sms/Cache
    rustup/toolchains
    site-packages
    systemtap/tapset/linux
)

for p in "${IGNORE[@]}"; do
    ARGS+=(--exclude "**/$p/")
done


clean_symlinks() {
    while read -r link; do

        target=$(readlink "$link")

        if [[ $target = "$FILES_D"/* ]] || [[ $target = *dotfiles* ]]; then

            if [[ ! -e $target ]]; then
                printf "Danging symlink %q => %q\n" \
                    "$link" \
                    "$target"

                rm -v "$link"
            fi
        fi
    done
}


# $HOME itself (no recurse)
fd "${ARGS[@]}" \
    --max-depth 1 \
    --search-path "$HOME" \
| clean_symlinks

# $HOME sub-paths (with recurse)
fd "${ARGS[@]}" \
    "${PATHS[@]}" \
| clean_symlinks
