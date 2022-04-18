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
    alacritty         # terminal emulator
    automake
    bash-completion
    bc                # maths
    bind-utils        # DNS cli tools
    cmake
    ctags
    curl
    diffutils
    dos2unix
    etckeeper         # /etc as a git repo
    fd-find           # fast file finder
    file
    fzf
    gcc
    git
    golang
    gzip
    htop
    httpie
    iftop
    inotify-tools
    irqbalance
    jq
    jwhois
    libpasswdqc-devel # Kong
    libyaml
    libyaml-devel
    libyaml-devel     # Kong
    lsof
    m4                # Kong
    man-db
    mkpasswd
    mlocate
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
    pre-commit        # fancy git pre-commit framework
    psutils
    python3
    python3-devel
    python3-dnf
    python3-pip
    readline-devel
    ripgrep
    rsync
    scdoc             # man-page/doc generator
    sed
    sqlite
    sqlite-devel
    strace
    taglib
    tcpdump
    telnet
    tmux
    traceroute
    tree
    unzip
    util-linux
    vim-common
    wget
    which
    wl-clipboard
    xdg-user-dirs
    xdg-utils
    zip
    zlib
    zlib-devel
    zlib-devel        # Kong
)

sudo dnf install -y "${PACKAGES[@]}"
