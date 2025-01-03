#!/usr/bin/env bash

# shellcheck source-path=SCRIPTDIR


if [[ -z ${_INEED_CLI_SOURCED:-} ]]; then
    source "$INEED_ROOT/lib.sh"

    readonly YES="+"
    readonly NO="-"

    _INEED_CLI_SOURCED=1
fi


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

get-installed-timestamp() {
    local -r name=$1

    if app-state::get "$name" installed-timestamp; then
        return
    fi

    local bin

    bin=$(driver-exec-quiet get-binary-name "$name" || echo "$name")
    bin=$(type -f -P "$bin")

    if [[ -z ${bin:-} ]]; then
        return
    fi

    bin=$(realpath "$bin")

    if [[ -n ${bin:-} && -e ${bin:-} ]]; then
        local t; t=$(date --iso-8601=seconds --reference="$bin")

        app-state::set \
            "$name" \
            installed-timestamp \
            "$t"

        echo "$t"
    fi
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
    printf "%-32s %-16s %s\n" "name" "version" "installed"
                                              # 2023-09-30T19:18:13-07:00
    printf "%-32s %-16s %s\n" "----" "-------" "-------------------------"
    for d in $(list-drivers); do
        local v; v=$(get-installed-version "$d")
        local t; t=$(get-installed-timestamp "$d")

        printf "%-32s %-16s %s\n" "$d" "${v:-$NO}" "${t:-$NO}"
    done
}


is-installed() {
    driver-exec-quiet is-installed "$1"
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
            mark="$YES"
        else
            mark="$NO"
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

    local -a args=()

    for arg in "$@"; do
        case $arg in
            --reinstall)
                reinstall=1
                ;;
            *)
                args+=("$arg")
                ;;
        esac
    done

    set -- "${args[@]}"

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
      '%s-%s-%s' \
      "$name" \
      "$version" \
      "$(basename "$url")"

    local fname; fname=$(cache-get "$url" "$base")

    driver-exec install-from-asset "$name" "$fname" "$version"

    echo "$name" "$(driver-exec get-installed-version "$name")"

    set-installed-version "$name" "$version"
    app-state::set "$name" installed-timestamp "$(date --iso-8601=seconds)"
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
        if ! is-installed "$d"; then
            continue
        fi
        install::cmd "$d"
    done
}

state::cmd() {
    local -r app=${1?app/driver name required}
    app-state::list "$app"
}

state::complete() {
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
