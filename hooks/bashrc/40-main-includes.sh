#!/usr/bin/env bash

set -euo pipefail

source ./lib/bash/generate.bash

rc-export BASH_USER_LIB "${HOME:?}/.local/lib/bash"

{
    if rc-command-exists stty; then
        rc-new-workfile key-bindings

        rc-workfile-if-interactive \
            rc-workfile-add-exec stty werase undef

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

# PATH
{
    rc-add-path --prepend PATH "$HOME/.local/bin"
    rc-rm-path PATH /usr/share/Modules/bin
    rc-rm-path PATH "$HOME/.composer/vendor/bin"
}

# MANPATH
{
    man_paths=(
        "$HOME/.local/share/man"
        "$HOME/.local/man"
    )

    for path in "${man_paths[@]}"; do
        [[ -e $path ]] || continue
        rc-add-path --prepend MANPATH "$path"
    done

    if [[ -e /etc/man_db.conf ]]; then
        awk '/^MANPATH_MAP/ {print $3}' /etc/man_db.conf \
            | sort -u \
            | while read -r dir; do
                [[ -e $dir ]] || continue
                rc-add-path --append  MANPATH "$dir"
            done
    else
        rc-add-path --append  MANPATH /usr/local/share/man
        rc-add-path --append  MANPATH /usr/share/man
    fi
}

{
    if rc-command-exists mise; then
        mise reshim
        shims=$HOME/.local/share/mise/shims
        if [[ -d $shims ]]; then
            rc-add-path PATH "$shims" --prepend --after "$HOME/.local/bin"
        fi
    fi
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
    if ! rc-command-exists mise; then
        rc-add-path PATH "$GOPATH/bin"
    fi
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

# node / npm
{
    rc-export NPM_CONFIG_USERCONFIG "$HOME/.config/npm/npmrc"

    if rc-command-exists mise; then
        rc-new-workfile node
        NODE=$(mise where node)
        if [[ -d $NODE/man ]]; then
            rc-add-path MANPATH "${NODE}/man"
        fi
        rc-workfile-close
    fi

    # clean up old nvm things
    rc-unset NVM_BIN
    rc-unset NVM_DIR
    rc-unset NVM_INC
    if have-builtin varsplice; then
        rc-varsplice --remove -g PATH "$HOME/.config/nvm/*"
    fi
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
    rc-workfile-add-dep "$RC_DEP_DEBUG"
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
        rc-workfile-add-dep "$RC_DEP_DEBUG"
        rc-workfile-include ./bash/app-wezterm.sh
        rc-workfile-close
    fi
}

# history
{
    rc-new-workfile history
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
