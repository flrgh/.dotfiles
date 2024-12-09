#!/usr/bin/env bash

set -euo pipefail

# Install desired OS packages
#
# Utilities, build-time deps, etc...
#
# This list isn't meant to be exhaustive or super duper well-maintained. It's
# just an effort to reduce the frequency of those "oh I forgot I need `foo-devel`
# and `lib-whatever` installed in order to run such-and-such" moments.

PACKAGES=(
    # fonts
    adobe-source-code-pro-fonts
    liberation-fonts

    # things installed for Kong development
    libpasswdqc-devel
    libyaml-devel
    m4
    perl-FindBin
    zlib-devel

    axel              # openresty build dep
    alacritty         # terminal emulator
    automake
    bc                # maths
    bear              # database generator for clang
    bind-utils        # DNS cli tools
    cargo             # rustlang package manager
    clang
    clang-tools-extra # provides clangd
    cmake
    ctags
    curl
    diffutils
    dos2unix
    duf               # modern version of df
    etckeeper         # /etc as a git repo
    fd-find           # fast file finder
    file
    fontconfig
    fontconfig-devel  # currently required to build alacritty
    fzf
    gcc
    gcc-c++
    git
    git-extras
    golang
    gzip
    htop
    httpie
    hub               # github CLI
    iftop
    inotify-tools
    iotop
    irqbalance
    jc                # convert text output from common tools to JSON
    jq
    jo                # command-line JSON object creation
    jwhois
    libtool           # nvim build dep
    libyaml
    libyaml-devel
    litecli           # nicer SQLite CLI
    lnav              # log file navigator
    lsd               # modern ls replacement
    lshw
    lsof
    man-db
    mkpasswd
    moreutils
    mycli             # nicer MySQL CLI
    musl-gcc
    net-tools         # netstat
    ninja-build
    nmap
    nmap-ncat
    openssl-devel
    openssl-libs
    pandoc
    patch
    pcre
    pcre-devel
    pcre2
    pgcli             # nicer Postgres CLI
    plocate
    pre-commit        # fancy git pre-commit framework
    psutils
    python3
    python3-devel
    python3-dnf
    python3-pip
    readline-devel
    ripgrep
    rsync
    rust
    rust-src
    scdoc             # man-page/doc generator
    sd                # find+replace (simpler, faster sed)
    sed
    ShellCheck
    sqlite
    sqlite-devel
    strace
    sysstat
    taglib
    tcpdump
    telnet
    tmux
    traceroute
    tree
    unzip
    valgrind
    valgrind-devel
    util-linux
    vim-common
    wabt              # WebAssembly Binary Toolkit: https://github.com/WebAssembly/wabt
    wget
    which
    wireshark
    wl-clipboard
    xdg-user-dirs
    xdg-utils
    zip
    zlib
    zlib-devel
)

sudo dnf install -y "${PACKAGES[@]}"

REMOVE=(
    bash-completion
    PackageKit-command-not-found
)

sudo dnf remove -y "${REMOVE[@]}"
