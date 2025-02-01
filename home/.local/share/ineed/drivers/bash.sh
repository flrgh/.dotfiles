#!/usr/bin/env bash

set -euo pipefail

#readonly URL=https://ftp.gnu.org/gnu/bash/
readonly MIRROR=https://mirrors.ocf.berkeley.edu/gnu/bash
readonly INDEX=${MIRROR}/

readonly PREFIX=$HOME/.local
readonly NAME=bash
readonly BIN=${PREFIX}/bin/${NAME}

SYSTEM_BASH=$(PATH="" command -v -p bash)
readonly SYSTEM_BASH

readonly ENABLED=(
    alias                    # enable shell aliases
    alt-array-implementation # enable an alternate array implementation that optimizes speed at the cost of space
    arith-for-command        # enable arithmetic for command
    array-variables          # include shell array variables
    bang-history             # turn on csh-style history substitution
    brace-expansion          # include brace expansion
    casemod-attributes       # include case-modifying variable attributes
    casemod-expansions       # include case-modifying word expansions
    command-timing           # enable the time reserved word and command timing
    cond-command             # enable the conditional command
    cond-regexp              # enable extended regular expression matching in conditional commands
    coprocesses              # enable coprocess supp and the coproc reserved word
    debugger                 # enable supp for bash debugger
    directory-stack          # enable builtins pushd/popd/dirs
    disabled-builtins        # allow disabled builtins to still be invoked
    dparen-arithmetic        # include ((...)) command
    extended-glob            # include ksh-style extended pattern matching
    function-import          # allow bash to import exported function definitions by default
    glob-asciiranges-default # force bracket range expressions in pattern matching to use the C locale by default
    help-builtin             # include the help builtin
    history                  # turn on command history
    job-control              # enable job control features
    multibyte                # enable multibyte characters if OS supps them
    net-redirections         # enable /dev/tcp/host/p redirection
    process-substitution     # enable process substitution
    progcomp                 # enable programmable completion and the complete builtin
    prompt-string-decoding   # turn on escape character decoding in prompts
    readline                 # turn on command line editing
    select                   # include select command
    separate-helpfiles       # use external files for help builtin documentation

    # dev-fd-stat-broken     # enable this option if stat on /dev/fd/N and fstat on file descriptor N don't return the same results
    # profiling              # allow profiling with gprof
    # single-help-strings    # store help documentation as a single string to ease translation
    # threads                # ={posix|solaris|pth|windows} # specify multithreading API
)

DISABLED=(
    direxpand-default     # enable the direxpand shell option by default
    rpath                 # do not hardcode runtime library paths
    extended-glob-default # force extended pattern matching to be enabled by default
    mem-scramble          # scramble memory on calls to malloc and free
    restricted            # enable a restricted shell
    static-link           # link bash statically, for use as a root shell
    strict-posix-default  # configure bash to be posix-conformant by default
    translatable-strings  # include support for $"..." translatable strings
    usg-echo-default      # a synonym for --enable-xpg-echo-default
    xpg-echo-default      # make the echo builtin expand escape sequences by default

    # largefile           # omit supp for large files
    # nls                 # do not use Native Language Supp
    # threads             # build without multithread safety
)

WITH=(
    bash-malloc             # use the Bash version of malloc

    # afs                   # if you are running AFS
    # curses                # use the curses library instead of the termcap library
    # gnu-ld                # assume the C compiler uses GNU ld [default=no]
    # gnu-malloc            # synonym for --with-bash-malloc
    # included-gettext      # use the GNU gettext library included here
    # installed-readline    # use a version of the readline library that is already installed
    # libiconv-prefix[=DIR] # search for libiconv in DIR/include and DIR/lib
    # libintl-prefix[=DIR]  # search for libintl in DIR/include and DIR/lib
    # libpth-prefix[=DIR]   # search for libpth in DIR/include and DIR/lib
)

WITHOUT=(
    # libpth-prefix   # search for libpth in includedir and libdir
    # libiconv-prefix # search for libiconv in includedir and libdir
    # libintl-prefix  # search for libintl in includedir and libdir
)

get-binary-name() {
    echo "$BIN"
}

is-installed() {
    [[ -x $BIN ]]
}

get-installed-version() {
    if is-installed; then
        "$BIN" -c 'printf "%s.%s.%s" "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}" "${BASH_VERSINFO[2]}"'
    fi
}

list-available-versions() {
    local html
    html=$(cache-get -q "$INDEX" "bash-versions.html")
    sed -n -r \
        -e 's/.*href="bash-([0-9]+\.[0-9]+\.[0-9]+)\.tar\.gz".*/\1/p' \
    < "$html"
}

get-asset-download-url() {
    local -r version=$1
    # e.g. https://mirrors.ocf.berkeley.edu/gnu/bash/bash-5.2.37.tar.gz
    echo "${MIRROR}/bash-${version}.tar.gz"
}

install-from-asset() {
    local -r asset=$1
    local -r version=$2

    cd "$(mktemp -d)"

    tar --strip-components 1 \
        -xzf "$asset"

    ./configure \
        --prefix="$PREFIX" \
        "${ENABLED[@]/#/--enable-}" \
        "${DISABLED[@]/#/--disable-}" \
        "${WITH[@]/#/--with-}" \
        "${WITHOUT[@]/#/--without-}"

    make
    make loadables
    make install
}
