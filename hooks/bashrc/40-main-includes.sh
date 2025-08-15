#!/usr/bin/env bash

set -euo pipefail

source ./lib/bash/generate.bash
source ./home/.local/lib/bash/array.bash

rc-export BASH_USER_LIB "${HOME:?}/.local/lib/bash"

declare -a _mps=()
declare -A _seen_mp=()

readonly MAN=$HOME/.local/share/man

add-man-path() {
    local -r mp=$1
    if [[ -n ${_seen_mp[$mp]:-} ]]; then
        return
    fi

    if [[ ! -d $mp ]]; then
        return
    fi

    _seen_mp[$mp]=1
    local subdir
    local rel

    case $mp in
        "$MAN")
            _mps=("$mp" "${_mps[@]}")
            rc-add-path --prepend MANPATH "$mp"
            ;;

        "$HOME"/*)
            shopt -s nullglob
            shopt -u failglob

            for subdir in "$mp"/man[0-9]; do
                rel=${MAN}${subdir#"$mp"}
                ./scripts/symlink-tree "$subdir" "$rel"
            done

            # clean up cruft
            rm -rfv \
                "$mp"/cat[0-9] \
                "$mp"/index.db \
                "$mp"/cs
            ;;

        *)
            _mps+=("$mp")
            rc-add-path --append MANPATH "$mp"
            ;;
    esac
}


{
    rc-new-workfile user-lib
    rc-workfile-add-dep "$RC_DEP_SET_VAR"
    rc-workfile-add-exec source "${BASH_USER_LIB:?}/__init.bash"
    rc-workfile-close
}

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

    if rc-command-exists mise; then
        mise reshim
        shims=$HOME/.local/share/mise/shims
        if [[ -d $shims ]]; then
            rc-add-path PATH "$shims" --prepend --after "$HOME/.local/bin"
        fi
    fi
}


# MANPATH
{
    add-man-path "$HOME/.local/share/man"

    if rc-command-exists manpath; then
        while read -d ":" -r path; do
            add-man-path "$path"
        done < <(manpath --global)
        unset path

    else
        add-man-path /usr/local/share/man
        add-man-path /usr/share/man
    fi

    rc-set-exported MANPATH
}

# aliases
{
    rc-alias grep 'grep --color=auto'
    rc-alias .. 'cd ..'
    if rc-command-exists lsd; then
        rc-alias ls "lsd -l"
    fi
}

# gh / github cli
{
    setup_gh() {
        if ! rc-command-exists gh; then
            log "gh is not installed"
            return
        fi

        local where; where=$(mise where gh)
        if [[ -z ${where:-} || ! -d $where ]]; then
            return
        fi

        shopt -s failglob
        add-man-path "$where"/*/share/man
    }
    setup_gh
}

{
    setup_git_cliff() {
        if ! rc-command-exists git-cliff; then
            log "git-cliff is not installed"
            return
        fi

        local where; where=$(mise where git-cliff)
        if [[ -z ${where:-} || ! -d $where ]]; then
            return
        fi

        shopt -s failglob
        ln -sfv -t "$MAN/man1" \
            "${where}"/*/man/git-cliff.1
    }

    setup_git_cliff
}

{
    setup_fzf() {
        if ! rc-command-exists fzf; then
            log "fzf not found"
            return
        fi

        local bin; bin=$(mise which fzf)

        # -R tells `man` to re-encode the input rather than formatting it for display
        MANOPT='-R' "$bin" --man > "$MAN/man1/fzf.1"
    }

    setup_fzf
}

{
    setup_ripgrep() {
        if ! rc-command-exists rg; then
            log "ripgrep (rg) not found"
            return
        fi

        mise exec ripgrep -- \
            rg --generate man \
        > "$MAN/man1/rg.1"
    }

    setup_ripgrep
}

# neovim
{
    if rc-command-exists nvim; then
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
    RUSTUP_HOME="$HOME/.local/rustup"

    rc-export CARGO_HOME
    rc-add-path PATH "$CARGO_HOME"/bin
    rc-export RUSTUP_HOME

    # https://blog.rust-lang.org/2023/03/09/Rust-1.68.0.html#cargos-sparse-protocol
    rc-export CARGO_REGISTRIES_CRATES_IO_PROTOCOL sparse

    if rc-command-exists rustup; then
        active=$(rustup show active-toolchain | awk '{print $1}')
        tc=${RUSTUP_HOME:?}/toolchains/${active:?}

        if [[ -d ${tc}/share/man ]]; then
            add-man-path "${tc}/share/man"
        fi

        unset active tc
    fi
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
        NODE=$(mise where node)
        if [[ -d $NODE/share/man ]]; then
            add-man-path "${NODE}/share/man"
        fi
    fi

    if [[ -d $HOME/.local/lib/node_modules/npm/man ]]; then
        add-man-path "$HOME/.local/lib/node_modules/npm/man"
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
    rc-workfile-add-dep user-lib
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
