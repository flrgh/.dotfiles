source ./lib/bash/common.bash
source ./lib/bash/facts.bash
source ./home/.local/lib/bash/string.bash
source ./home/.local/lib/bash/array.bash
source ./home/.local/lib/bash/stack.bash

export BUILD_BASHRC_DIR=${BUILD_ROOT:?BUILD_ROOT undefined}/bashrc
export BUILD_BASHRC_INC=$BUILD_BASHRC_DIR/rc.d
export BUILD_BASHRC_PRE=$BUILD_BASHRC_DIR/rc.pre.d
export BUILD_BASHRC_DEPS=$BUILD_BASHRC_DIR/deps
export BUILD_BASHRC_FILE=${BUILD_ROOT}/home/.bashrc

init-namespace bash

source ./build/home/.config/env

have-builtin() {
    local -r name=${1:?}
    shift

    have "builtins-${name}" "$@"
}

# shellcheck disable=SC2034
{
    declare -g _LABEL
    declare -g _FILE
    declare -g _DEPS

    declare -g _ALL_FILES=bashrc-all-files
    declare -g RC_DEP_INIT="rc-init"
    declare -g RC_DEP_POST_INIT="rc-post-init"
    declare -g RC_DEP_LOG="rc-log"
    declare -g RC_DEP_DEBUG="rc-debug"
    declare -g RC_DEP_TIMER="rc-timer"
    declare -g RC_DEP_ENV="rc-env"
    declare -g RC_DEP_ENV_POST="env-post"
    declare -g RC_DEP_RESET_VAR="rc-var-reset"
    declare -g RC_DEP_SET_VAR="rc-set-var"
    declare -g RC_DEP_CLEAR_VAR="rc-clear-var"
    declare -g RC_DEP_ALIAS_RESET="rc-alias-reset"
    declare -g RC_DEP_ALIAS_SET="rc-alias-create"
    declare -g RC_DEP_RESET_FUNCTION="rc-function-reset"
    declare -g RC_DEP_SET_FUNCTION="rc-function-set"
    declare -g RC_DEP_CLEAR_FUNCTION="rc-function-clear"
    declare -g RC_DEP_BUILTINS="rc-builtins"
    declare -g RC_DEP_PATHSET="rc-pathset"
}

_is_timed() {
    local -r label=${1:?}
    is-true "bashrc-${label}-timed"
}

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
    if (( depth > 0 )); then
        if list-contains "$list" "$dep"; then
            #list-add "bashrc-${dep}-rdeps" "$item" "true"
            return 0
        fi
    fi

    list-add "$list" "$dep"
    #list-add "bashrc-${dep}-rdeps" "$item" "true"

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
        _recursive_add_dep "$item" "$elem" "$depth"
    done
}

_have_working_file() {
    [[ -n ${_LABEL:-} && -n ${_FILE:-} && -n ${_DEPS:-} ]]
}


_require_working_file() {
    _have_working_file || fatal "no current working file set"
}

_can_time() {
    local label=${1:-}

    if [[ -z ${label:-} ]]; then
        _require_working_file
        label=$_LABEL
    fi

    _recursive_has_dep "$label" "$RC_DEP_TIMER" \
        && ! _recursive_has_dep "$label" "rc-timer-post"
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

    if (( $# == 1 )); then
        printf -- '%s' "$1" >> "$name"
    else
        printf -- "$@" >> "$name"
    fi
}

declare -ga _TIMER_STACK=()

_timer_start() {
    if ! have-builtin timer; then
        return
    fi

    local -r fname=${1:?}
    local -r name=${2:?}

    stack-push _TIMER_STACK "$name"

    local label
    array-join-var label '/' "${_TIMER_STACK[@]}"
    _rc_append "$fname" 'timer start "%s"\n' "$label"
}

_timer_stop() {
    if ! have-builtin timer; then
        return
    fi

    local -r fname=${1:?}

    local label
    array-join-var label '/' "${_TIMER_STACK[@]}"
    _rc_append "$fname" 'timer stop # "%s"\n' "${label:?}"

    stack-pop _TIMER_STACK
}

rc-workfile-timer-start() {
    local -r name=${1:?}
    _require_working_file
    _timer_start "$_FILE" "$name"
}

rc-workfile-timer-stop() {
    _require_working_file
    _timer_stop "$_FILE"
}


_add_exec() {
    local -r name=$1
    shift

    local cmd=$1
    shift

    local -a args=()
    local type
    type=$(type -t "$cmd" || true)

    if [[ $cmd != "builtin" && $cmd != "export" && $cmd != "timer" ]]; then
        case $type in
            builtin)
                args=(builtin "$cmd")
                ;;
            function)
                args=("$cmd")
                ;;
            file)
                local path
                if path=$(command -v "$cmd") && [[ -n ${path:-} ]]; then
                    args=("$path")
                else
                    args=("$cmd")
                fi
                ;;

            *)
                args=("$cmd")
                ;;
        esac
    else
        args=("$cmd")
    fi

    local quoted
    for arg in "$@"; do
        printf -v quoted '%q' "$arg"
        args+=( "$quoted" )
    done

    _rc_append "$name" '%s\n' "${args[*]}"
}

_has_deps() {
    local -r item=$1
    local -r list="bashrc-${item}-deps"

    if list-is-empty "$list"; then
        return 1
    fi
}

_unset_workfile() {
    unset _LABEL _FILE _DEPS
}

rc-workfile-add-exec() {
    _require_working_file
    _add_exec "$_FILE" "$@"
}

rc-workfile-append() {
    _require_working_file
    _rc_append "$_FILE" "$@"
}

rc-workfile-append-line() {
    _require_working_file
    _rc_append "$_FILE" '%s\n' "${1:?}"
}

rc-workfile-close() {
    _require_working_file
    if _can_time "$_LABEL"; then
        set-true "bashrc-${_LABEL}-timed"
    else
        set-false "bashrc-${_LABEL}-timed"
    fi
    _unset_workfile
}

_maybe_close() {
    if _have_working_file; then
        rc-workfile-close
    fi
}

trap _maybe_close EXIT

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

_set_working_file() {
    local -r label=${1:?}
    _LABEL=$label
    _FILE=$file
    _DEPS=bashrc-${label}-deps
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

    _set_working_file "$label"
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
        log "include($fname)"
    else
        log "include-external($fname)"
    fi

    rc-workfile-append '# BEGIN: %s\n' "$fname"

    local time_it=0
    if _can_time; then
        time_it=1
        log "file $short will be timed"
    else
        log "file $short will not be timed"
    fi

    if (( time_it == 1 )); then
        _timer_start "$_FILE" "include($short)"
    fi

    if (( is_repo_file == 0 )); then
        rc-workfile-append-line '# shellcheck disable=all'
        rc-workfile-append-line '{'
    fi

    rc-workfile-append '%s\n' "$(< "$fname")"

    if (( is_repo_file == 0 )); then
        rc-workfile-append-line '}'
    fi

    if (( time_it == 1 )); then
        _timer_stop "$_FILE"
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
    rc-workfile-append-line "$dec"

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
    log "function($fn)"
    local dec; dec=$(rc-dump-function "$fn")

    if (( DEBUG > 0 )) && _can_time "$_LABEL"; then
       _timer_start "$_FILE" "function($fn)"
    fi

    _rc_append "$_FILE" '%s\n' "$dec"

    if (( DEBUG > 0 )) && _can_time "$_LABEL"; then
       _timer_stop "$_FILE"
    fi
}

rc-workfile-else() {
    rc-workfile-append-line 'else'
}

rc-workfile-fi() {
    rc-workfile-append-line 'fi'
}

rc-workfile-if-login() {
    rc-workfile-append-line 'if (( __RC_LOGIN_SHELL == 1 )); then'

    if (( $# > 0 )); then
        "$@"
        rc-workfile-fi
    fi
}

rc-workfile-if-interactive() {
    rc-workfile-append-line 'if (( __RC_INTERACTIVE_SHELL == 1 )); then'

    if (( $# > 0 )); then
        "$@"
        rc-workfile-fi
    fi
}

rc-var() {
    local -r var=$1
    local -r value=$2

    _save_workfile

    rc-workfile-open "$RC_DEP_SET_VAR"
    log "var($var)"
    rc-workfile-append '%s=%q\n' "$var" "$value"

    _restore_workfile
}

rc-workfile-var() {
    local -r var=$1
    local -r value=$2

    log "var($var)"
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
    log "alias($name)"
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

    if var-exists "$name" && var-equals "$name" "$value"; then
        log "SKIP (exists) export($name)"
        return
    fi

    _save_workfile

    rc-workfile-open "$RC_DEP_SET_VAR"
    log "export($name)"
    rc-workfile-add-exec export "${name}=${value}"

    _restore_workfile
}

rc-reset-var() {
    local -r name=$1

    _save_workfile

    rc-workfile-open "$RC_DEP_RESET_VAR"
    log "unset($name)"
    rc-workfile-add-exec unset "$name"

    _restore_workfile
}

rc-unset() {
    local -r name=$1

    _save_workfile

    rc-workfile-open "$RC_DEP_CLEAR_VAR"
    log "unset($name)"
    rc-workfile-append 'unset %s\n' "$name"

    _restore_workfile
}

rc-command-exists() {
    command -v "$1" &>/dev/null
}

rc-add-path() {
    _save_workfile

    rc-workfile-open "$RC_DEP_PATHSET"
    if have-builtin varsplice; then
        rc-workfile-add-exec builtin varsplice "$@"
    else
        local append_prepend=0
        local before_after=0
        for arg in "$@"; do
            case $arg in
                --append|--prepend) append_prepend=1 ;;
                --before|--after) before_after=1 ;;
            esac
        done

        if (( append_prepend == 1 && before_after == 1 )); then
            local -a args=()
            for arg in "$@"; do
                case $arg in
                    --append|--prepend) ;;
                    *) args+=("$arg") ;;
                esac
            done
            set -- "${args[@]}"
        fi

        rc-workfile-add-exec __rc_add_path "$@"
    fi

    _restore_workfile
}

rc-rm-path() {
    _save_workfile

    rc-workfile-open "$RC_DEP_PATHSET"
    if have-builtin varsplice; then
        rc-workfile-add-exec builtin varsplice --remove "$@"
    else
        rc-workfile-add-exec __rc_rm_path "$@"
    fi

    _restore_workfile
}

rc-varsplice() {
    if ! have-builtin varsplice; then
        fatal "tried to call varsplice but we don't got it"
    fi

    _save_workfile

    rc-workfile-open "$RC_DEP_PATHSET"
    rc-workfile-add-exec builtin varsplice "$@"

    _restore_workfile
}

rc-init() {
    if [[ -e $BUILD_BASHRC_FILE ]]; then
        rm "$BUILD_BASHRC_FILE"
    fi

    if [[ -d $BUILD_BASHRC_DIR ]]; then
        rm -rfv "$BUILD_BASHRC_DIR"
    fi

    init-facts
    reset-namespace bash

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

_get_rdeps() {
    local -r item=${1:?}

    shopt -s nullglob
    local -a rdeps=("${FACT_DIR}"/bashrc-*-deps.list/"${item}")

    rdeps=( "${rdeps[@]%-deps.list/*}" )
    rdeps=( "${rdeps[@]##*/bashrc-}" )

    declare -ga _RDEPS=( "${rdeps[@]}" )
}

_clear_rdeps() {
    local -r item=${1:?}

    _get_rdeps "$item"

    for dep in "${_RDEPS[@]}"; do
        _clear_dep "$dep" "$item"
    done
}

_handle() {
    local -r item=$1

    : $(( _STEPS++ ))

    local -r list="bashrc-${item}-deps"

    #log "checking: $item ($count deps)"

    if list-is-empty "$list"; then
        _FINAL+=("$item")
        _clear_rdeps "$item"
        return 0
    fi

    local -a deps
    get-list-items "$list"
    deps=("${FACT_LIST[@]}")

    local -i oops=0
    for dep in "${deps[@]}"; do
        if [[ ! -e ${BUILD_BASHRC_INC}/${dep} ]]; then
            oops=1
            log "WARN: $item depends on $dep, but we couldn't find it"
        fi
    done

    if (( oops == 1 )); then
        _clear_rdeps "$item"
        _FAILED+=("$item")
    fi

    return 1
}

rc-finalize() {
    _unset_workfile

    log "finalizing $BUILD_BASHRC_FILE"

    local -a all
    get-list-items "$_ALL_FILES"
    all=("${FACT_LIST[@]}")

    declare -ga _FINAL=()
    declare -ga _REMAIN=("${all[@]}")

    set -- "${_REMAIN[@]}"

    declare -ga _FAILED=()

    declare -gi _STEPS=0

    while (( $# > 0 )); do
        local item=$1
        shift

        if _handle "$item"; then
            :
        elif array-contains "$item" "${_FAILED[@]}"; then
            :
        else
            set -- "$@" "$item"
        fi
    done

    log "COMPLETE ($_STEPS steps):"
    printf '\t%s\n' "${_FINAL[@]}"

    if (( ${#_FAILED[@]} > 0 )); then
        log "FAILED:"
        printf '\t%s\n' "${_FAILED[@]}"

        fatal "something broke"
    fi

    echo '# vim: set ft=sh:' >> "$BUILD_BASHRC_FILE"
    for f in "${_FINAL[@]}"; do
        local path="$BUILD_BASHRC_INC/$f"
        local lines
        lines=$(shfmt --simplify --minify "$path" \
            | grep -c -vE '^[\s]*$' \
            || true
        )

        if (( lines == 0 )); then
            echo "SKIP $f (empty)"
            continue
        fi

        {
            printf '# label: %s\n' "$f"

            local timer_label="label($f)"
            if _is_timed "$f"; then
                _timer_start /dev/stdout "$timer_label"
            fi

            cat "$BUILD_BASHRC_INC/$f"

            if _is_timed "$f"; then
                _timer_stop /dev/stdout
            fi
        } >> "$BUILD_BASHRC_FILE"
    done

    bash -n "$BUILD_BASHRC_FILE" || {
        fatal "syntax error in generated .bashrc file"
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
            fatal "'shfmt .bashrc' returned non-zero"
        }
    fi

    if rc-command-exists shellcheck; then
        shellcheck --norc --shell bash "$BUILD_BASHRC_FILE" || {
            fatal "'shellcheck .bashrc' returned non-zero"
        }
    fi
}
