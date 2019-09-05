#!/bin/bash

set -eu
shopt -s nullglob dotglob

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}")"  && pwd)"
DIR=${DIR%/}


INSTALL_PATH=${1:-$HOME}
INSTALL_PATH=${INSTALL_PATH%/}

export INSTALL_PATH
export REPO_ROOT=$DIR

link() {
    local target=$1
    local linkName=$2

    linkDir=$(dirname "$linkName")
    if [[ ! -e $linkDir ]]; then
	    mkdir -p "$linkDir"
    fi

    if $DIR/linked.py "$target" "$linkName"; then
        return 0
    fi
    ln -T -f -v -s "$target" "$linkName"
}

run_hooks() {
    local path=$1
    local name=$2

    echo "Running $name hooks:"
    for f in "$path"/*; do
        local t
        t=$(mktemp)
        local name; name=$(basename "$f")
        printf "  - %s\n" "$name"
        if ! "$f" < /dev/null &> "$t"; then
            echo "$name exited nonzero: $?"
            cat "$t"
        fi
        rm "$t"
    done
}


echo Installing to $INSTALL_PATH

run_hooks "$DIR/hooks.pre" pre-install

LINK_FILES_DIR=$DIR/files.d

find "$LINK_FILES_DIR" -mindepth 1 -type f -print0 \
| while read -r -d '' target; do
    linkName=${target/$LINK_FILES_DIR/$INSTALL_PATH}
    link "$target" "$linkName"
done

LINK_DIRS_DIR=$DIR/dirs.d
find "$LINK_DIRS_DIR" -maxdepth 1 -mindepth 1 -type d -print0 \
| while read -r -d '' target; do
    linkName=${target/$LINK_DIRS_DIR/$INSTALL_PATH}
    link "$target" "$linkName"
done

run_hooks "$DIR/hooks.post" post-install
