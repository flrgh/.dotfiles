#!/usr/bin/env bash


source "$INEED_ROOT/lib.sh"

is-command() {
    local name=${1%::cmd}

    function-exists "${name}::cmd"
}

is-driver() {
    local -r name=$1

    [[ -n $name && -n ${INEED_DRIVERS_HASH[$name]} ]]
}

have-completion() {
    local name=${1%::cmd}

    function-exists "${name}::complete"
}

complete-from-array() {
    local -r name=$1
    local -rn ref=${name}


    local oifs="$IFS"
    IFS=$' '

    local words="${ref[*]}"
    IFS="$oifs"

    COMPREPLY=()
    for elem in $(compgen -W "$words" "$cur"); do
        COMPREPLY+=("$elem")
    done

}

complete-from-drivers() {
    if [[ -n $_DRIVER ]]; then
        return
    fi

    complete-from-array INEED_DRIVERS_LIST
}

complete-from-commands() {
    if [[ -n ${_COMMAND:-} ]]; then
        return
    fi

    complete-from-array INEED_CLI_COMMANDS
}

get-available-versions() {
    local -r name=$1
    for v in $(driver-exec list-available-versions "$name"); do
        normalize-version "$v"
    done
}

get-installed-version() {
    local -r name=$1
    local v; v=$(driver-exec get-installed-version "$name")
    normalize-version "$v"
}

get-latest-version() {
    local -r name="$1"

    local v; v=$(driver-exec get-latest-version "$name")

    normalize-version "$v"
}



complete-from-versions() {
    local -r name=$1

    declare -ga _VERSIONS=()

    for v in $(get-available-versions "$name"); do
        _VERSIONS+=("$v")
    done


    complete-from-array __VERSIONS

    unset __VERSIONS
}


list::cmd() {
    for d in $(list-drivers); do
        local v; v=$(get-installed-version "$d")
        if [[ -n $v ]]; then
            printf "%-32s %s\n" "$d" "$v"
        fi
    done
}

is-installed() {
    driver-exec is-installed "$1"
}

version() {
    get-installed-version "$1"
}

version::complete() {
    complete-from-drivers
}


usage::cmd() {
    echo "Usage:"
    echo
    echo "    $0 <command> [...]"
    echo
    echo "Commands:"
    echo
    local cmd
    for cmd in ${INEED_CLI_COMMANDS[@]}; do
        echo "    $cmd"
    done
}

get-latest::cmd() {
    local -r name="$1"

    get-latest-version "$name"
}

get-latest::complete() {
    complete-from-drivers
}


available-versions::complete() {
    complete-from-drivers
}

available-versions::cmd() {
    local -r name="$1"

    get-available-versions "$name"
}

need-install() {
    local -r name="$1"
    local -r version="$2"

    if ! is-installed "$name"; then
        return
    fi

    local current; current=$(version "$name")

    [[ $current != "$version" ]]
}

install::cmd() {
    local reinstall=0

    for (( i = 0; i < $#; i ++ )); do
        local arg=$1
        shift;
        case $arg in
            --reinstall)
                echo setting reinstall
                reinstall=1
                ;;
            *)
                set -- "$@" "$arg"
                ;;
        esac
    done

    local -r name=$1
    local version=${2:-latest}

    if [[ $version == latest ]]; then
        version=$(get-latest-version "$name")
    fi

    if ! need-install "$name" "$version"; then
        if (( reinstall == 1 )); then
            echo "reinstalling $name $version"
        else
            echo "$name $version is already installed"
            return
        fi
    fi

    local url; url=$(driver-exec get-asset-download-url "$name" "$version")

    echo "Downloading $name $version from $url"

    local fname; fname=$(cache-get "$url")

    driver-exec install-from-asset "$name" "$fname" "$version"
}

install::complete() {
    for (( i = ${#COMP_WORDS[@]}; i > 0; i-- )); do
        local word=${COMP_WORDS[$i]}

        if is-driver "$word"; then
            complete-from-versions "$word"
            return
        fi
    done

    complete-from-drivers
}

_bash_completion::cmd() {
    cat "$INEED_ROOT"/completion.sh
}

declare -ga INEED_CLI_COMMANDS=()
declare -gA INEED_CLI_COMMANDS_HASH=()
for fn in $(compgen -A function); do
    if is-command "$fn"; then
        fn=${fn%::cmd}
        INEED_CLI_COMMANDS+=("$fn")
        INEED_CLI_COMMANDS_HASH[$fn]=1
    fi
done

declare -ga INEED_DRIVERS_LIST=()
declare -gA INEED_DRIVERS_HASH=()
for d in $(list-drivers); do
    INEED_DRIVERS_LIST+=("$d")
    INEED_DRIVERS_HASH[$d]=1
done
