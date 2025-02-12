#!/usr/bin/env bash

set -euo pipefail

source ./lib/bash/generate.bash
source ./lib/bash/facts.bash

rc-export BASH_USER_LIB "${HOME:?}/.local/lib/bash"

{
    if rc-command-exists stty; then
        rc-new-workfile key-bindings
        rc-workfile-append-line 'if [[ $- = *i* ]]; then'
        rc-workfile-add-exec stty werase undef
        rc-workfile-append-line 'fi'
        rc-workfile-close
    fi
}

{
    rc-new-workfile user-functions
    rc-workfile-add-dep function-dispatch
    rc-workfile-include ./bash/user-functions.bash
    rc-workfile-close
}

{
    rc-new-workfile config
    rc-workfile-add-dep "$RC_DEP_ENV"
    rc-workfile-include ./bash/conf-shell.sh
    rc-workfile-close
}

# common path tweaks
{
    rc-add-path --prepend PATH "$HOME/.local/bin"

    rc-rm-path PATH /usr/share/Modules/bin
    rc-rm-path PATH "$HOME/.composer/vendor/bin"

    rc-add-path --prepend MANPATH "$HOME/.local/man"
    rc-add-path --prepend MANPATH "$HOME/.local/share/man"
    rc-add-path --append  MANPATH /usr/local/share/man
    rc-add-path --append  MANPATH /usr/share/man
}

# aliases
{
    rc-alias grep 'grep --color=auto'
    rc-alias .. 'cd ..'
    if command -v lsd &>/dev/null; then
        rc-alias ls "lsd -l"
    fi
}

# neovim
{
    if command -v nvim &>/dev/null; then
        rc-alias vim nvim
        rc-export EDITOR nvim
    fi
}

# go
{
    # https://github.com/golang/go/wiki/GOPATH
    GOPATH=$HOME/.local/go
    rc-export GOPATH
    rc-add-path PATH "$GOPATH/bin"
}

# rust
{
    CARGO_HOME=$HOME/.local/cargo
    rc-export CARGO_HOME
    rc-add-path PATH "$CARGO_HOME"/bin
    rc-export RUSTUP_HOME "$HOME/.local/rustup"

    # https://blog.rust-lang.org/2023/03/09/Rust-1.68.0.html#cargos-sparse-protocol
    rc-export CARGO_REGISTRIES_CRATES_IO_PROTOCOL sparse
}

# ruby
{
    rc-new-workfile lang-ruby
    GEM_HOME="$HOME/.local/gems"
    rc-export GEM_HOME
    rc-add-path PATH "${GEM_HOME}"/bin
}

# python
{
    PYTHONSTARTUP=$HOME/.local/.startup.py
    if [[ -f $PYTHONSTARTUP ]]; then
        rc-export PYTHONSTARTUP
    fi

    IPYTHONDIR="$HOME/.config/ipython"
    mkdir -p "$IPYTHONDIR"
    rc-export IPYTHONDIR
}

# npm
{
    rc-export NPM_CONFIG_USERCONFIG "$HOME/.config/npm/npmrc"
}

# docker
{
    # https://docs.docker.com/reference/cli/docker/
    rc-export DOCKER_CONFIG "${XDG_CONFIG_HOME:?}/docker"

    # OpenTelemetry (just a placeholder to remind future me to check this out)
    rc-unset DOCKER_CLI_OTEL_EXPORTER_OTLP_ENDPOINT

    rc-export DOCKER_SCOUT_CACHE_DIR "${XDG_CACHE_HOME:?}/docker-scout"
}

# azure CLI
{
    # azure cli configuration
    #
    # see https://docs.microsoft.com/en-us/cli/azure/azure-cli-configuration
    rc-export AZURE_CONFIG_DIR "$HOME/.config/azure"
}

# ssh
{
    rc-new-workfile ssh
    rc-workfile-add-dep "function-links-to"
    rc-workfile-include ./bash/app-ssh.sh
    rc-workfile-close
}

# minijinja CLI
{
    rc-new-workfile app-config-minijinja
    rc-export MINIJINJA_CONFIG_FILE "${XDG_CONFIG_HOME:-"$HOME/.config"}/minijinja.toml"
    rc-workfile-close
}

# wezterm
{
    if command -v wezterm; then
        rc-new-workfile wezterm
        rc-workfile-include ./bash/app-wezterm.sh
        rc-workfile-close
    fi
}

# history
{
    rc-new-workfile history
    rc-workfile-add-dep "prompt-command"
    if have-builtin stat; then
        __get_mtime() {
            local -r fname=${1:?}
            declare -g REPLY=0
            builtin stat "$fname" || return 1
            REPLY=${STAT[mtime]:-0}
        }
    else
        __get_mtime() {
            local -r fname=${1:?}
            declare -g REPLY=0
            local mtime
            if mtime=$(stat -c '%Y' "$fname"); then
                REPLY=${mtime}
            else
                return 1
            fi
        }
    fi

    rc-workfile-add-function __get_mtime

    rc-workfile-include ./bash/conf-history.sh
    rc-workfile-close
}

# systemd
{
    # this must be an empty string and not unset
    rc-workfile-open "$RC_DEP_RESET_VAR"
    rc-workfile-append-line 'export SYSTEMD_PAGER=""'
    rc-workfile-close
}
