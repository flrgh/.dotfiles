source "$REPO_ROOT"/lib/bash/common.bash
source "$BASH_USER_LIB"/functions/strip-whitespace.bash
source "$BASH_USER_LIB"/version.bash

_FACT_BOOL="bool"
_FACT_VERSION="version"
_FACT_LIST="list"
_FACT_TEXT="txt"
_FACT_LOCATION="location"

__init() {
    declare -g FACT_NAME
    declare -g FACT_TYPE
    declare -g FACT_PATH

    declare -g FACT
    declare -ga FACT_LIST=()

    declare -g FACT_DIR
    FACT_DIR=${BUILD_ROOT:?BUILD_ROOT undefined}/facts
}

__init

init-facts() {
    [[ -n ${FACT_DIR:-} ]] || __init
    mkdir -p "$FACT_DIR"
}

reset-facts() {
    [[ -n ${FACT_DIR:-} ]] || __init

    if [[ -e $FACT_DIR ]]; then
        rm -rf "$FACT_DIR"
    fi

    init-facts
}

declare -ga _FACT_VARS=(
    FACT_NAME FACT_TYPE FACT_PATH FACT FACT_LIST
)

_unset_current_fact() {
    unset FACT_NAME FACT_TYPE FACT_PATH
}

_set_current_fact() {
    local -r name=${1:?}
    local -r type=${2:?}

    _unset_current_fact

    declare -g FACT_NAME=$name
    declare -g FACT_TYPE=$type
    declare -g FACT_PATH=${FACT_DIR:?}/${FACT_NAME}.${FACT_TYPE}

    unset FACT FACT_LIST
    declare -g FACT
    declare -ga FACT_LIST=()
}

_require_fact() {
    [[ -n ${FACT_NAME:-} ]] || fatal "current fact not set"
}

_touch_fact() {
    _require_fact
    touch "${FACT_PATH:?}"
}

_fact_exists() {
    _require_fact
    [[ -e $FACT_PATH ]]
}

_require_fact_type() {
    local -r type=${1:?}

    _require_fact

    [[ $FACT_TYPE == "$type" ]] \
        || fatal "$FACT_NAME is a $FACT_TYPE and not a ${type}"
}

_require_non_list() {
    _require_fact

    [[ $FACT_TYPE != "$_FACT_LIST" ]] \
        || fatal "$FACT_NAME is a $_FACT_LIST"
}

_require_list() {
    _require_fact_type "$_FACT_LIST"
}

_reset_fact_value() {
    unset FACT FACT_LIST
    declare -g FACT
    declare -ga FACT_LIST=()
}

_read_list() {
    _require_list
    _reset_fact_value

    shopt -s nullglob dotglob
    local -a arr=( "$FACT_PATH"/* )
    FACT_LIST=( "${arr[@]##*/}" )
}

_read_plain() {
    _require_non_list
    _reset_fact_value
    FACT=$(< "$FACT_PATH")
    strip-whitespace FACT
}

_read_fact() {
    _require_fact

    _fact_exists || fatal "$FACT_TYPE $FACT_NAME does not exist"

    case $FACT_TYPE in
        "$_FACT_LIST") _read_list  ;;
        *)             _read_plain ;;
    esac
}

get-fact() {
    local -r name=${1:?}
    local -r type=${2:?}

    _set_current_fact "$name" "$type"
    _read_fact
    _unset_current_fact
}

set-fact() {
    local -r name=${1:?}
    local -r type=${2:?}
    local value=${3:?}

    _set_current_fact "$name" "$type"

    local -r path=${FACT_PATH:?}

    if [[ $value == '-' ]]; then
        value=$(cat)
    fi

    strip-whitespace value

    printf '%s' "$value" > "$FACT_PATH"
    _unset_current_fact
}

create-list() {
    local -r name=${1:?}

    _set_current_fact "$name" "$_FACT_LIST"

    if _fact_exists; then
        fatal "list $name already exists"
    fi

    mkdir "${FACT_PATH:?}"
    _unset_current_fact
}

_list_contains() {
    local -r value=${1:?}

    _require_fact
    _fact_exists || fatal "list ${FACT_NAME:?} not found"

    [[ -e ${FACT_PATH:?}/$value ]]
}

list-contains() {
    local -r name=${1:?}
    local value=${2:?}

    _set_current_fact "$name" "$_FACT_LIST"

    local ec=0
    _list_contains "$value" || ec=1
    _unset_current_fact
    return "$ec"
}

list-add() {
    local -r name=${1:?}
    local value=${2:?}
    local create=${3:-no}

    if truthy "$create"; then
        create-list-if-not-exists "$name"
    fi

    _set_current_fact "$name" "$_FACT_LIST"

    if ! _list_contains "$value"; then
        touch "${FACT_PATH:?}/${value}"
    fi

    _unset_current_fact
}

list-path() {
    local -r name=${1:?}

    _set_current_fact "$name" "$_FACT_LIST"
    _fact_exists || fatal "list ${FACT_NAME:?} not found"
    FACT=${FACT_PATH:?}
    _unset_current_fact
}


list-exists() {
    local -r name=${1:?}

    _set_current_fact "$name" "$_FACT_LIST"

    local ec=0
    _fact_exists || ec=1
    _unset_current_fact

    return "$ec"
}

create-list-if-not-exists() {
    local -r name=${1:?}

    if list-exists "$name"; then
        return
    else
        create-list "$name"
    fi
}

list-size() {
    local -r name=${1:?}

    _set_current_fact "$name" "$_FACT_LIST"
    _fact_exists || fatal "list ${FACT_NAME:?} not found"

    _read_list
    echo "${#FACT_PATH[@]}"

    _unset_current_fact
}

list-remove() {
    local -r name=${1:?}
    local value=${2:?}

    _set_current_fact "$name" "$_FACT_LIST"
    _fact_exists || fatal "list ${FACT_NAME:?} not found"

    local -r path=${FACT_PATH}/${value}
    if [[ -e $path ]]; then
        rm "$path"
    fi

    _unset_current_fact
}

get-list-items() {
    local -r name=${1:?}

    _set_current_fact "$name" "$_FACT_LIST"
    _read_list
    _unset_current_fact
}

list-has-items() {
    local -r name=${1:?}
    get-list-items "$name"
    (( ${#FACT_LIST[@]} > 0 ))
}

list-is-empty() {
    local -r name=${1:?}
    get-list-items "$name"
    (( ${#FACT_LIST[@]} == 0 ))
}


set-true() {
    local -r name=${1:?}
    set-fact "${name}" "${_FACT_BOOL}" 1
}

set-false() {
    local -r name=${1:?}
    set-fact "${name}" "${_FACT_BOOL}" 0
}

is-true() {
    local -r name=${1:?}
    get-fact "${name}" "${_FACT_BOOL}" || return 1
    (( FACT == 1 ))
}

set-version() {
    local -r name=${1:?}
    local -r version=${2:?}

    _version_parse "$version" || return 1

    set-fact "${name}" "${_FACT_VERSION}" "$version"
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

    get-fact "${name}" "${_FACT_VERSION}" || return 1

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

    set-fact "${name}" "${_FACT_LOCATION}" "$path"
}

get-location() {
    local -r name=${1:?}
    get-fact "${name}" "${_FACT_LOCATION}"
}

set-var-value() {
    local -r name=${1:?}
    local -r value=${2:?}
    set-fact "var-value-${name}" "$_FACT_TEXT" "$value"
}

set-var-exported() {
    local -r name=${1:?}
    set-true "var-exported-${name}"
}

set-var-source() {
    local -r name=${1:?}
    local -r src=${2:?}

    set-fact "var-source-${name}" "$_FACT_TEXT" "$src"
}

var-exists() {
    local -r name=${1:?}
    _set_current_fact "var-value-${name}" "$_FACT_TEXT"
    _fact_exists || return 1
    _unset_current_fact
}

get-var-value() {
    local -r name=${1:?}
    _set_current_fact "var-value-${name}" "$_FACT_TEXT"
    _fact_exists || return 1
    _read_fact
    _unset_current_fact
}

var-equals() {
    local -r name=${1:?}
    local -r value=${2:?}
    get-var-value  "$name" || return 1
    local rc=1
    if [[ $FACT == "$value" ]]; then
        rc=0
    fi
    _unset_current_fact
    return "$rc"
}
