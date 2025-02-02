#!/usr/bin/env bash

set -euo pipefail
shopt -s extglob nullglob

#readonly URL=https://ftp.gnu.org/gnu/bash/
readonly MIRROR=https://mirrors.ocf.berkeley.edu/gnu/bash
readonly INDEX=${MIRROR}/

readonly PREFIX=$HOME/.local
readonly NAME=bash
readonly BIN=${PREFIX}/bin/${NAME}

SYSTEM_BASH=$(PATH="" command -v -p bash)
readonly SYSTEM_BASH

readonly BUILTINS=(
    stat
)

readonly BINDIR=$PREFIX/bin
readonly INCDIR=$PREFIX/include
readonly LIBDIR=$PREFIX/lib
readonly LIBEXECDIR=$PREFIX/libexec
readonly LIBBASH=$LIBDIR/bash
readonly LOADABLES=$LIBBASH/loadables

readonly LOCATIONS=(
  prefix="$PREFIX"         # [/usr/local]           install architecture-independent files in PREFIX
  bindir="$BINDIR"         # [EPREFIX/bin]          user executables
  libdir="$LIBDIR"         # [EPREFIX/lib]          object code libraries
  includedir="$INCDIR"     # [PREFIX/include]       C header files
  libexecdir="$LIBEXECDIR" # [EPREFIX/libexec]      program executables

  # exec-prefix=EPREFIX    # [PREFIX]               install architecture-dependent files in EPREFIX
  # sbindir=DIR            # [EPREFIX/sbin]         system admin executables
  # sysconfdir=DIR         # [PREFIX/etc]           read-only single-machine data
  # sharedstatedir=DIR     # [PREFIX/com]           modifiable architecture-independent data
  # localstatedir=DIR      # [PREFIX/var]           modifiable single-machine data
  # runstatedir=DIR        # [LOCALSTATEDIR/run]    modifiable per-process data
  # oldincludedir=DIR      # [/usr/include]         C header files for non-gcc
  # datarootdir=DIR        # [PREFIX/share]         read-only arch.-independent data root
  # datadir=DIR            # [DATAROOTDIR]          read-only architecture-independent data
  # infodir=DIR            # [DATAROOTDIR/info]     info documentation
  # localedir=DIR          # [DATAROOTDIR/locale]   locale-dependent data
  # mandir=DIR             # [DATAROOTDIR/man]      man documentation
  # docdir=DIR             # [DATAROOTDIR/doc/bash] documentation root
  # htmldir=DIR            # [DOCDIR]               html documentation
  # dvidir=DIR             # [DOCDIR]               dvi documentation
  # pdfdir=DIR             # [DOCDIR]               pdf documentation
  # psdir=DIR              # [DOCDIR]               ps documentation
)

# constants from config-top.h, config.h, config-bot.h
readonly DEFINES=(
    # The default value of the PATH variable.
    DEFAULT_PATH_VALUE="${BINDIR}:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"

    # The default path for enable -f
    DEFAULT_LOADABLE_BUILTINS_PATH="$LOADABLES"

    # The value for PATH when invoking `command -p'.  This is only used when
    # the Posix.2 confstr () function, or CS_PATH define are not present.
    STANDARD_UTILS_PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc:/usr/etc"

    # Define to 1 if you want the shell to re-check $PATH if a hashed filename
    # no longer exists.  This behavior is the default in Posix mode.
    CHECKHASH_DEFAULT="0"

    # Define to the maximum level of recursion you want for the eval builtin
    # and trap handlers (since traps are run as if run by eval).
    # 0 means the limit is not active. */
    EVALNEST_MAX="100"

    # Define to the maximum level of recursion you want for the source/. builtin.
    # 0 means the limit is not active. */
    SOURCENEST_MAX="100"

    # Define to set the initial size of the history list ($HISTSIZE). This must
    # be a string
    HISTSIZE_DEFAULT="${HISTSIZE:-500}"
)

readonly ENABLED=(
    alias                    # enable shell aliases
    alt-array-implementation # enable an alternate array implementation that optimizes speed at the cost of space
    arith-for-command        # enable arithmetic for command
    array-variables          # include shell array variables
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
    #bang-history          # turn on csh-style history substitution
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

    cp -a ./config-top.h{,.bak}

    local CFLAGS="-g -O2"
    for def in "${DEFINES[@]}"; do
        key=${def%%=*}
        value=${def#*=}

        if [[ $value =~ ^[0-9]+$ && $key != "HISTSIZE_DEFAULT" ]]; then
            :
        else
            value=\"${value}\"
        fi

        local prefix="#define $key "
        local line="${prefix}${value}"
        local checkdef="#ifndef ${key}"

        if grep -qxF "$checkdef" ./config-top.h; then
            CFLAGS=${CFLAGS:+"$CFLAGS "}-D${key}=\'${value}\'
        else
            sed -r -i -e "s|.*${prefix}.*|${line}|" ./config-top.h
        fi
    done

    ./configure \
        "${LOCATIONS[@]/#/--}" \
        "${ENABLED[@]/#/--enable-}" \
        "${DISABLED[@]/#/--disable-}" \
        "${WITH[@]/#/--with-}" \
        "${WITHOUT[@]/#/--without-}" \
        "CFLAGS=${CFLAGS}"

    make
    make loadables
    make install
    make install-headers

    # the bash install plumbing builds and installs _all_ example
    # loadables in ~/.local/lib/bash, so we need to do some cleanup
    for elem in "${LIBBASH}"/*; do
        local base=${elem##*/}
        if [[ $base = *.sh || $base = *.bash || ! -f $elem ]]; then
            continue
        fi
        rm -v "$elem"
    done

    local loadables=${PWD}/examples/loadables/
    mkdir -p "$LOADABLES"
    install -v \
        -t "$LOADABLES" \
        "${BUILTINS[@]/#/"${loadables}"}"

    mkdir -p "$PREFIX"/var/log
    cat ./config.log > "$PREFIX"/var/log/bash.config.log
}
