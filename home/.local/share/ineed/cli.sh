#!/usr/bin/env bash

# shellcheck source-path=SCRIPTDIR


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


complete-from-args() {
    local oifs="$IFS"
    IFS=$' '

    local words="$*"
    IFS="$oifs"

    COMPREPLY=()
    # shellcheck disable=SC2154
    for elem in $(compgen -W "$words" "$cur"); do
        COMPREPLY+=("$elem")
    done
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

    complete-from-args "${INEED_DRIVERS_LIST[@]}"
}


complete-from-commands() {
    if [[ -n ${_COMMAND:-} ]]; then
        return
    fi

    complete-from-args "${INEED_CLI_COMMANDS[@]}"
}


get-available-versions() {
    local -r name=$1

    for v in $(driver-exec list-available-versions "$name"); do
        normalize-version "$v"
    done
}


get-installed-version() {
    local -r name=$1

    if app-state::get "$name" version; then
        return
    fi

    # state is not yet populated, need to refresh from the binary itself
    local v; v=$(driver-exec get-installed-version "$name")
    v=$(normalize-version "$v")

    set-installed-version "$name" "$v"

    echo "$v"
}


set-installed-version() {
    local -r name=$1
    local -r version=$2
    app-state::set "$name" version "$(normalize-version "$version")"
}


get-latest-version() {
    local -r name="$1"

    local v; v=$(driver-exec get-latest-version "$name")

    normalize-version "$v"
}


complete-from-versions() {
    local -r name=$1

    local versions=()

    for v in $(get-available-versions "$name"); do
        versions+=("$v")
    done


    complete-from-args "${versions[@]}"
}


list::cmd() {
    printf "%-32s %s\n" "name" "version"
    printf "%-32s %s\n" "----" "-------"
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


drivers::cmd() {
    printf "%-32s %s\n" "name" "installed"
    printf "%-32s %s\n" "----" "---------"
    for d in "${INEED_DRIVERS_LIST[@]}"; do
        local mark
        if is-installed "$d"; then
            mark="✓"
        else
            mark="✗"
        fi
        printf "%-32s %s\n" "$d" "$mark"
    done
}


usage::cmd() {
    echo "Usage:"
    echo
    echo "    $0 <command> [...]"
    echo
    echo "Commands:"
    echo
    local cmd
    for cmd in "${INEED_CLI_COMMANDS[@]}"; do
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


run-command() {
    local -r cmd=$1
    shift

    if ! is-command "$cmd"; then
        echo "Unknown command: $cmd"
        exit 1
    fi

    local -r fn="${cmd}::cmd"

    "$fn" "$@"
}


install::cmd() {
    local reinstall=0

    for (( i = 0; i < $#; i ++ )); do
        local arg=$1
        shift;
        case $arg in
            --reinstall)
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

    local base;
    printf -v base \
      '%s.%s' \
      "$name" \
      "$(basename "$url")"

    local fname; fname=$(cache-get "$url" "$base")

    driver-exec install-from-asset "$name" "$fname" "$version"

    echo "$name" "$(driver-exec get-installed-version "$name")"

    set-installed-version "$name" "$version"
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


update::cmd() {
    for d in "${INEED_DRIVERS_LIST[@]}"; do
        install::cmd "$d"
    done
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
