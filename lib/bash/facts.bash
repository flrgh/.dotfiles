source "$REPO_ROOT"/lib/bash/common.bash
source "$BASH_USER_LIB"/functions/strip-whitespace.bash
source "$BASH_USER_LIB"/version.bash

__init() {
    declare -g FACT
    declare -g FACT_DIR
    FACT_DIR=${BUILD_ROOT:?BUILD_ROOT undefined}/facts
}

__init

reset-facts() {
    [[ -n ${FACT_DIR:-} ]] || __init

    if [[ -e $FACT_DIR ]]; then
        rm -rf "$FACT_DIR"
    fi

    mkdir -p "$FACT_DIR"
}

get-fact() {
    local -r name=$1
    local -r path=${FACT_DIR:?}/${name}
    FACT=
    test -f "$path" && FACT=$(< "$path")
}

set-fact() {
    local -r name=${1:?}
    local value=${2:?}

    if [[ $value == '-' ]]; then
        value=$(cat)
        strip-whitespace value
    fi

    local -r path=${FACT_DIR:?}/${name}
    printf '%s' "$value" > "$path"
}

set-true() {
    local -r name=${1:?}
    set-fact "${name}.bool" 1
}

set-false() {
    local -r name=${1:?}
    set-fact "${name}.bool" 0
}

is-true() {
    local -r name=${1:?}
    get-fact "${name}.bool" || return 1
    (( FACT == 1 ))
}

set-version() {
    local -r name=${1:?}
    local -r version=${2:?}

    _version_parse "$version" || return 1

    set-fact "${name}.version" "$version"
}

set-have() {
    local -r name=$1
    set-true "have.${name}"

    if (( $# > 1 )); then
        set-version "$name" "$2"
    fi
}

set-not-have() {
    local -r name=$1
    set-false "have.${name}"
}

have() {
    local -r name=$1
    is-true "have.${name}" || return 1

    if [[ -n ${2:-} && -n ${3:-} ]]; then
        fact-version-compare "$name" "$2" "$3"
    fi
}

fact-version-compare() {
    local -r name=${1:?}
    local -r op=${2:?}
    local -r rhs=${3:?}

    get-fact "${name}.version" || return 1

    local version=${FACT:?}
    version-compare "$version" "$op" "$rhs"
}

set-location() {
    local -r name=${1:?}
    local -r path=${2:?}
    local -r ignore_absent=${3:-0}

    if (( ignore_absent == 0 )); then
        test -e "$path" || return 1
    fi

    set-fact "${name}.location" "$path"
}

get-location() {
    local -r name=${1:?}
    get-fact "${name}.location"
}
