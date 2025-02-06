source ./lib/bash/common.bash
source ./lib/bash/facts.bash
source ./home/.local/lib/bash/string.bash

export BUILD_BASHRC_DIR=${BUILD_ROOT:?BUILD_ROOT undefined}/bashrc
export BUILD_BASHRC_INC=$BUILD_BASHRC_DIR/rc.d
export BUILD_BASHRC_PRE=$BUILD_BASHRC_DIR/rc.pre.d
export BUILD_BASHRC_DEPS=$BUILD_BASHRC_DIR/deps
export BUILD_BASHRC_FILE=${BUILD_ROOT}/home/.bashrc

source ./build/home/.config/env

declare -g _LABEL
declare -g _FILE
declare -g _DEPS

declare -g _ALL_FILES=bashrc-all-files

RC_DEP_INIT="rc-init"
RC_DEP_POST_INIT="rc-post-init"
RC_DEP_LOG="rc-log"
RC_DEP_DEBUG="rc-debug"
RC_DEP_TIMER="rc-timer"
RC_DEP_ENV="env"
RC_DEP_ENV_POST="env-post"

RC_DEP_RESET_VAR="rc-var-reset"
RC_DEP_SET_VAR="rc-set-var"
RC_DEP_CLEAR_VAR="rc-clear-var"

RC_DEP_ALIAS_RESET="rc-alias-reset"
RC_DEP_ALIAS_SET="rc-alias-create"

RC_DEP_RESET_FUNCTION="rc-function-reset"
RC_DEP_SET_FUNCTION="rc-function-set"
RC_DEP_CLEAR_FUNCTION="rc-function-clear"

log() {
    if [[ -n ${_LABEL:-} ]]; then
        printf '[%s] ' "${_LABEL}"
    fi

    echo "$@"
}

_recursive_has_dep() {
    local -r item=${1:?}
    local -r dep=${2:?}

    local -r list="bashrc-${item}-deps"

    if ! list-exists "$list"; then
        return 1
    fi

    local -a deps
    get-list-items "$list"
    deps=("${FACT_LIST[@]}")

    local -A seen=()

    for elem in "${deps[@]}"; do
        if [[ $elem == "$dep" ]]; then
            return 0
        fi

        if [[ -n ${seen[$elem]:-} ]]; then
            continue
        fi

        seen[$elem]=yes

        if _recursive_has_dep "$elem" "$dep"; then
            return 0
        fi
    done

    return 1
}

_recursive_add_dep() {
    local -r item=${1:?}
    local -r dep=${2:?}
    local -i depth=${3:-0}

    depth=$(( depth + 1 ))
    if (( depth > 20 )); then
        fatal "stack overflow or something"
    fi

    local -r list="bashrc-${item}-deps"
    list-add "$list" "$dep"
    list-add "bashrc-${dep}-rdeps" "$item" "true"

    local -r deplist="bashrc-${dep}-deps"
    if ! list-exists "$deplist"; then
        return
    fi

    local -a deps
    get-list-items "$deplist"
    deps=("${FACT_LIST[@]}")

    local -A seen=()

    for elem in "${deps[@]}"; do
        if [[ -n ${seen[$elem]:-} ]]; then
            continue
        fi
        seen[$elem]=$elem
        _recursive_add_dep "$item" "$elem"
    done
}


_have_working_file() {
    [[ -n ${_LABEL:-} && -n ${_FILE:-} && -n ${_DEPS:-} ]]
}

_require_working_file() {
    _have_working_file || fatal "no current working file set"
}

_rc_append() {
    local -r name=$1
    shift

    if (( DEBUG > 0 )); then
        local -i i
        for (( i = 0; i < ${#BASH_LINENO[@]}; i++ )); do
            printf '# %2d %-48s:%-3d %s\n' \
                "$i" \
                "${BASH_SOURCE[i]#"${REPO_ROOT}/"}" \
                "${BASH_LINENO[i]}" \
                "${FUNCNAME[i]}" \
            >> "$name"
        done
    fi

    printf -- "$@" >> "$name"
}

_add_exec() {
    local -r name=$1
    shift

    # don't quote the first arg (just because)
    local args=("$1")
    shift

    local quoted
    for arg in "$@"; do
        printf -v quoted '%q' "$arg"
        args+=( "$quoted" )
    done

    _rc_append "$name" '%s\n' "${args[*]}"
}

rc-workfile-add-exec() {
    _require_working_file
    _add_exec "$_FILE" "$@"
}

rc-workfile-append() {
    _require_working_file
    _rc_append "$_FILE" "$@"
}

rc-workfile-close() {
    _require_working_file
    unset _LABEL _FILE _DEPS
}

_save_workfile() {
    if _have_working_file; then
        [[ -z ${__SAVED_LABEL:-} ]] || fatal "cannot save twice"
        declare -g __SAVED_LABEL=${_LABEL}
        declare -g __SAVED_FILE=${_FILE}
        declare -g __SAVED_DEPS=${_DEPS}
        unset _LABEL _FILE _DEPS
    fi
}

_restore_workfile() {
    if [[ -n ${__SAVED_LABEL:-} ]]; then
        declare -g _LABEL=${__SAVED_LABEL}
        declare -g _FILE=${__SAVED_FILE}
        declare -g _DEPS=${__SAVED_DEPS}
        unset __SAVED_LABEL __SAVED_FILE __SAVED_DEPS
    fi
}

rc-workfile-open() {
    if _have_working_file; then
        rc-workfile-close
    fi

    local -r label=${1:?}
    local -r file=${BUILD_BASHRC_INC}/${label}

    if [[ ! -f $file ]]; then
        fatal "workfile $file not found"
    fi

    _LABEL=$label
    _FILE=$file
    _DEPS=bashrc-${label}-deps
}

rc-have-workfile() {
    _have_working_file
}

rc-new-workfile() {
    local -r label=${1:?}
    local -r file=${BUILD_BASHRC_INC}/${label}

    if [[ -e $file ]]; then
        echo "error: $file already exists"
        exit 1
    fi

    touch "$file"

    rc-workfile-open "$label"

    create-list "$_DEPS"
    list-add "$_ALL_FILES" "$label"

    rc-workfile-append '# label: %s\n' "$label"

    if [[ $label != rc-* ]]; then
        rc-workfile-add-dep "$RC_DEP_POST_INIT"
    fi
}

rc-workfile-add-dep() {
    local -r dep=${1:?}
    _require_working_file
    if [[ $_LABEL == "$dep" ]]; then
        fatal "invalid self-dependency ($_LABEL)"
    fi
    _recursive_add_dep "$_LABEL" "$dep"
    #list-add "bashrc-${dep}-rdeps" "$_LABEL" "true"
}

rc-workfile-include() {
    _require_working_file
    local fname=${1:?}
    local -i non_repo_file=${2:-0}
    [[ -f $fname ]] || fatal "file ($fname) not found"

    local cwd='./'
    fname=${fname/#"$cwd"/"$PWD/"}

    local short
    short=${fname#"$BUILD_BASHRC_DIR/"}
    short=${short#"$REPO_ROOT/home/.local/bash/"}
    short=${short#"$REPO_ROOT/"}
    short=${short#"$HOME/"}

    local -i is_repo_file=0
    if (( non_repo_file == 0 )) && [[ "$fname" = "${REPO_ROOT}"/* ]]; then
        is_repo_file=1
    fi

    rc-workfile-append '# BEGIN: %s\n' "$fname"

    local time_it=0
    if _recursive_has_dep "$_LABEL" "$RC_DEP_TIMER" \
        && ! _recursive_has_dep "$_LABEL" "rc-timer-post"; then
        time_it=1
    fi

    if (( time_it == 1 )); then
        rc-workfile-append '__rc_timer_start "include(%s)"\n' "$short"
    fi

    if (( is_repo_file == 0 )); then
        rc-workfile-append '# shellcheck disable=all\n'
        rc-workfile-append '\n{\n'
    fi

    rc-workfile-append '%s\n' "$(< "$fname")"

    if (( is_repo_file == 0 )); then
        rc-workfile-append '\n}\n'
    fi

    if (( time_it == 1 )); then
        rc-workfile-append '__rc_timer_stop\n'
    fi

    rc-workfile-append '# END: %s\n\n' "$fname"
}

rc-workfile-include-external() {
    rc-workfile-include "$1" 1
}

rc-has-dep() {
    local -r label=${1:?}
    local -r dep=bashrc-${2:?}-deps

    list-exists "$dep" && list-contains "$dep" "$label"
}

rc-includef() {
    local -r name=${BUILD_BASHRC_INC}/${1}.sh
    shift
    _rc_append "$name" "$@"
}

rc-declare() {
    local -r var=$1
    shift

    local dec; dec=$(declare -p "$var")
    if [[ -z $dec ]]; then
        return 1
    fi

    if _have_working_file && [[ $_LABEL != "$RC_DEP_SET_VAR" ]]; then
        rc-workfile-add-dep "$RC_DEP_SET_VAR"
    fi

    _save_workfile

    rc-workfile-open "$RC_DEP_SET_VAR"
    rc-workfile-append '%s\n' "$dec"

    _restore_workfile
}

rc-dump-function() {
    local -r fn=$1
    local dec; dec=$(declare -f "$fn")

    if [[ -z $dec ]]; then
        return 1
    fi

    echo "$dec"
}

rc-workfile-add-function() {
    _require_working_file
    local -r fn=$1
    local dec; dec=$(rc-dump-function "$fn")
    _rc_append "$_FILE" '%s\n' "$dec"
}


rc-var() {
    local -r var=$1
    local -r value=$2

    _save_workfile

    rc-workfile-open "$RC_DEP_SET_VAR"
    rc-workfile-append '%s=%q\n' "$var" "$value"

    _restore_workfile
}

rc-workfile-var() {
    local -r var=$1
    local -r value=$2

    rc-workfile-append '%s=%q\n' "${var:?}" "${value:?}"
}

rc-have-file() {
    local -r name=${1:?}
    list-contains "$_ALL_FILES" "$name"
}

rc-alias() {
    local -r name=$1
    local -r cmd=$2

    _save_workfile

    rc-workfile-open "$RC_DEP_ALIAS_SET"
    rc-workfile-add-exec alias "${name}=${cmd}"

    _restore_workfile
}

rc-require-var() {
    local -r name=${1:?}
    if [[ -z ${name:-} ]]; then
        fatal "var name required"
    fi

    if ! declare -p "$name" >/dev/null; then
        fatal "var $name is not declared"
    fi

    [[ -n ${!name:-} ]] || fatal "var $name is empty"
}

rc-export() {
    local -r name=$1
    local value=${2:-}

    if [[ -z ${value:-} ]]; then
        rc-require-var "$name"
        value=${!name:?}
    fi

    _save_workfile

    rc-workfile-open "$RC_DEP_SET_VAR"
    rc-workfile-add-exec export "${name}=${value}"

    _restore_workfile
}

rc-reset-var() {
    local -r name=$1

    _save_workfile

    rc-workfile-open "$RC_DEP_RESET_VAR"
    rc-workfile-add-exec unset "$name"

    _restore_workfile
}

rc-unset() {
    local -r name=$1

    _save_workfile

    rc-workfile-open "$RC_DEP_CLEAR_VAR"
    rc-workfile-append 'unset %s\n' "$name"

    _restore_workfile
}

rc-command-exists() {
    command -v "$1" &>/dev/null
}

rc-add-path() {
    _save_workfile

    rc-workfile-open rc-pathset
    if have varsplice; then
        rc-workfile-add-exec varsplice "$@"
    else
        rc-workfile-add-exec __rc_add_path "$@"
    fi

    _restore_workfile
}

rc-rm-path() {
    _save_workfile

    rc-workfile-open rc-pathset
    if have varsplice; then
        rc-workfile-add-exec varsplice --remove "$@"
    else
        rc-workfile-add-exec __rc_rm_path "$@"
    fi

    _restore_workfile
}

rc-varsplice() {
    if ! have varsplice; then
        fatal "tried to call varsplice but we don't got it"
    fi

    _save_workfile

    rc-workfile-open rc-pathset
    rc-workfile-add-exec varsplice "$@"

    _restore_workfile
}

rc-init() {
    if [[ -e $BUILD_BASHRC_FILE ]]; then
        rm "$BUILD_BASHRC_FILE"
    fi

    if [[ -d $BUILD_BASHRC_DIR ]]; then
        rm -rfv "$BUILD_BASHRC_DIR"
    fi

    reset-facts

    mkdir -vp \
        "$BUILD_BASHRC_INC" \
        "$BUILD_BASHRC_PRE" \
        "$BUILD_BASHRC_DEPS"

    create-list "$_ALL_FILES"
}

_clear_dep() {
    local -r item=${1:?}
    local -r dep=${2:?}

    list-remove "bashrc-${item}-deps" "$dep"
}

_clear_rdeps() {
    local -r item=${1:?}
    local -r list="bashrc-${item}-rdeps"

    if ! list-exists "$list"; then
        return
    fi

    local -a rdeps
    get-list-items "$list"
    rdeps=("${FACT_LIST[@]}")

    for rdep in "${rdeps[@]}"; do
        _clear_dep "$rdep" "$item"
    done
}

rc-finalize() {
    echo "finalizing $BUILD_BASHRC_FILE"

    local -a all
    get-list-items "$_ALL_FILES"
    all=("${FACT_LIST[@]}")

    local -a final=()
    local -a remain=("${all[@]}")

    set -- "${remain[@]}"

    local -a failed=()

    while (( $# > 0 )); do
        local item=$1
        shift

        local -a deps
        get-list-items "bashrc-${item}-deps"
        deps=("${FACT_LIST[@]}")

        local -i count=${#deps[@]}

        if (( count == 0 )); then
            final+=("$item")
            _clear_rdeps "$item"

        else
            local -i oops=0
            for dep in "${deps[@]}"; do
                if [[ ! -e ${BUILD_BASHRC_INC}/${dep} ]]; then
                    oops=1
                    echo "WARN: $item depends on $dep, but we couldn't find it"
                fi
            done

            if (( oops == 1 )); then
                _clear_rdeps "$item"
                failed+=("$item")
            else
                set -- "$@" "$item"
            fi
        fi
    done

    echo "COMPLETE:"
    printf '\t%s\n' "${final[@]}"

    if (( ${#failed[@]} > 0 )); then
        echo "FAILED:"
        printf '\t%s\n' "${failed[@]}"

        fatal "something broke"
    fi

    echo '# vim: set ft=sh:' >> "$BUILD_BASHRC_FILE"
    for f in "${final[@]}"; do
        cat "$BUILD_BASHRC_INC/$f" >> "$BUILD_BASHRC_FILE"
    done

    bash -n "$BUILD_BASHRC_FILE" || {
        echo "FATAL: syntax error in generated .bashrc file" >&2
        exit 1
    }

    if rc-command-exists shfmt; then
        shfmt \
            --write \
            --language-dialect bash \
            --simplify \
            --indent 4 \
            --binary-next-line \
            "$BUILD_BASHRC_FILE" \
        || {
            echo "FATAL: 'shfmt .bashrc' returned non-zero" >&2
            exit 1
        }
    fi

    if rc-command-exists shellcheck; then
        shellcheck "$BUILD_BASHRC_FILE" || {
            echo "FATAL: 'shellcheck .bashrc' returned non-zero" >&2
            exit 1
        }
    fi
}
