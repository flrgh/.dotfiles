source ./lib/bash/common.bash
source ./home/.local/lib/bash/functions/strip-whitespace.bash
source ./home/.local/lib/bash/version.bash
source ./home/.local/lib/bash/stack.bash

FACT_TYPE_BOOL="bool"
FACT_TYPE_VERSION="version"
FACT_TYPE_LIST="list"
FACT_TYPE_TEXT="txt"
FACT_TYPE_LOCATION="location"

FACT_NS_GLOBAL="global"
FACT_ROOT=${BUILD_ROOT:?}/facts

__FACT_INIT=0

_set_namespace() {
    local ns=${1:?}
    declare -g FACT_NS=$ns
    declare -g FACT_DIR=${FACT_ROOT}/${FACT_NS}
}

_init() {
    if (( __FACT_INIT == 1 )); then
        return
    fi

    __FACT_INIT=1

    unset FACT_NAME
    unset FACT_TYPE
    unset FACT_PATH
    unset FACT_NS
    unset FACT_DIR
    unset FACT
    unset FACT_LIST
    unset FACT_NS_STACK

    declare -g FACT_NAME
    declare -g FACT_TYPE
    declare -g FACT_PATH

    declare -ga FACT_NS_STACK=("$FACT_NS_GLOBAL")
    _set_namespace "$FACT_NS_GLOBAL"

    declare -g FACT
    declare -ga FACT_LIST=()
}

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

    [[ $FACT_TYPE != "$FACT_TYPE_LIST" ]] \
        || fatal "$FACT_NAME is a $FACT_TYPE_LIST"
}

_require_list() {
    _require_fact_type "$FACT_TYPE_LIST"
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
        "$FACT_TYPE_LIST") _read_list  ;;
        *)                 _read_plain ;;
    esac
}

_list_contains() {
    local -r value=${1:?}

    _require_fact
    _fact_exists || fatal "list ${FACT_NAME:?} not found"

    [[ -e ${FACT_PATH:?}/$value ]]
}

init-facts() {
    _init
    mkdir -p "$FACT_DIR"
}

reset-facts() {
    init-facts

    if [[ -e $FACT_DIR ]]; then
        rm -rf "${FACT_DIR:?}"
    fi

    mkdir -p "$FACT_DIR"
}

init-namespace() {
    local -r ns=${1:?}

    init-facts

    _set_namespace "$ns"
    mkdir -p "$FACT_DIR"
}

reset-namespace() {
    local -r ns=${1:?}

    _init

    _set_namespace "$ns"

    if [[ -e $FACT_DIR ]]; then
        rm -rf "${FACT_DIR:?}"
    fi

    init-namespace "$ns"
}

push-namespace() {
    local -r ns=${1:?}
    stack-push FACT_NS_STACK "${FACT_NS:?}"
    _set_namespace "$ns"
}

pop-namespace() {
    stack-pop FACT_NS_STACK
    _set_namespace "${REPLY:?}"
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

    _set_current_fact "$name" "$FACT_TYPE_LIST"

    if _fact_exists; then
        fatal "list $name already exists"
    fi

    mkdir "${FACT_PATH:?}"
    _unset_current_fact
}

list-contains() {
    local -r name=${1:?}
    local value=${2:?}

    _set_current_fact "$name" "$FACT_TYPE_LIST"

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

    _set_current_fact "$name" "$FACT_TYPE_LIST"

    if ! _list_contains "$value"; then
        touch "${FACT_PATH:?}/${value}"
    fi

    _unset_current_fact
}

list-path() {
    local -r name=${1:?}

    _set_current_fact "$name" "$FACT_TYPE_LIST"
    _fact_exists || fatal "list ${FACT_NAME:?} not found"
    FACT=${FACT_PATH:?}
    _unset_current_fact
}


list-exists() {
    local -r name=${1:?}

    _set_current_fact "$name" "$FACT_TYPE_LIST"

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

    _set_current_fact "$name" "$FACT_TYPE_LIST"
    _fact_exists || fatal "list ${FACT_NAME:?} not found"

    _read_list
    echo "${#FACT_PATH[@]}"

    _unset_current_fact
}

list-remove() {
    local -r name=${1:?}
    local value=${2:?}

    _set_current_fact "$name" "$FACT_TYPE_LIST"
    _fact_exists || fatal "list ${FACT_NAME:?} not found"

    local -r path=${FACT_PATH}/${value}
    if [[ -e $path ]]; then
        rm "$path"
    fi

    _unset_current_fact
}

get-list-items() {
    local -r name=${1:?}

    _set_current_fact "$name" "$FACT_TYPE_LIST"
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
    set-fact "${name}" "${FACT_TYPE_BOOL}" 1
}

set-false() {
    local -r name=${1:?}
    set-fact "${name}" "${FACT_TYPE_BOOL}" 0
}

is-true() {
    local -r name=${1:?}
    get-fact "${name}" "${FACT_TYPE_BOOL}" || return 1
    (( FACT == 1 ))
}

set-version() {
    local -r name=${1:?}
    local -r version=${2:?}

    _version_parse "$version" || return 1

    set-fact "${name}" "${FACT_TYPE_VERSION}" "$version"
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

    get-fact "${name}" "${FACT_TYPE_VERSION}" || return 1

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

    set-fact "${name}" "${FACT_TYPE_LOCATION}" "$path"
}

get-location() {
    local -r name=${1:?}
    get-fact "${name}" "${FACT_TYPE_LOCATION}"
}

get-builtin-location() {
    local -r name=${1:?}
    push-namespace bash
    get-fact "builtins-${name}" "${FACT_TYPE_LOCATION}"
    pop-namespace
}


set-var-value() {
    local -r name=${1:?}
    local -r value=${2:?}
    push-namespace env
    set-fact "var-value-${name}" "$FACT_TYPE_TEXT" "$value"
    pop-namespace
}

set-var-exported() {
    local -r name=${1:?}
    push-namespace env
    set-true "var-exported-${name}"
    pop-namespace
}

set-var-source() {
    local -r name=${1:?}
    local -r src=${2:?}

    push-namespace env
    set-fact "var-source-${name}" "$FACT_TYPE_TEXT" "$src"
    pop-namespace
}

var-exists() {
    local -r name=${1:?}
    push-namespace env
    _set_current_fact "var-value-${name}" "$FACT_TYPE_TEXT"
    _fact_exists || {
        pop-namespace
        return 1
    }
    _unset_current_fact
    pop-namespace
}

get-var-value() {
    local -r name=${1:?}
    push-namespace env
    _set_current_fact "var-value-${name}" "$FACT_TYPE_TEXT"
    _fact_exists || {
        pop-namespace
        return 1
    }
    _read_fact
    _unset_current_fact
    pop-namespace
}

var-equals() {
    local -r name=${1:?}
    local -r value=${2:?}

    push-namespace env
    get-var-value  "$name" || {
        pop-namespace
        return 1
    }

    local rc=1
    if [[ $FACT == "$value" ]]; then
        rc=0
    fi
    _unset_current_fact
    pop-namespace
    return "$rc"
}


# vim: set ft=sh:
