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
    axel              # openresty build dep
    alacritty         # terminal emulator
    automake
    bash-completion
    bc                # maths
    bear              # database generator for clang
    bind-utils        # DNS cli tools
    cargo             # rustlang package manager
    cmake
    ctags
    curl
    diffutils
    dos2unix
    duf               # modern version of df
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
    iotop
    irqbalance
    jc                # convert text output from common tools to JSON
    jq
    jo                # command-line JSON object creation
    jwhois
    libpasswdqc-devel # Kong
    libyaml
    libyaml-devel
    libyaml-devel     # Kong
    litecli           # nicer SQLite CLI
    lnav              # log file navigator
    lsd               # modern ls replacement
    lshw
    lsof
    m4                # Kong
    man-db
    mkpasswd
    mlocate
    mycli             # nicer MySQL CLI
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
    perl-FindBin      # kong-build-tools
    pgcli             # nicer Postgres CLI
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
    wget
    which
    wireshark
    wl-clipboard
    xdg-user-dirs
    xdg-utils
    zip
    zlib
    zlib-devel
    zlib-devel        # Kong
)

sudo dnf install -y "${PACKAGES[@]}"
