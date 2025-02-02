source "$REPO_ROOT"/lib/bash/common.bash
source "$REPO_ROOT"/lib/bash/facts.bash
source "$BASH_USER_LIB"/string.bash

export BUILD_BASHRC_DIR=${BUILD_ROOT:?BUILD_ROOT undefined}/bashrc

export BUILD_BASHRC_INC=$BUILD_BASHRC_DIR/rc.d
export BUILD_BASHRC_PRE=$BUILD_BASHRC_DIR/rc.pre.d
export BUILD_BASHRC_FILE=$BUILD_BASHRC_DIR/.bashrc

bashrc-append() {
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

bashrc-includef() {
    local -r name=${BUILD_BASHRC_INC}/${1}.sh
    shift
    bashrc-append "$name" "$@"
}

bashrc-pref() {
    local -r name=${BUILD_BASHRC_PRE}/${1}.sh
    shift
    bashrc-append "$name" "$@"
}

bashrc-pre-exec() {
    local -r name=$1
    shift

    local args=()
    local quoted
    for arg in "$@"; do
        printf -v quoted '%q' "$arg"
        args+=( "$quoted" )
    done

    bashrc-pref "$name" '%s\n' "${args[*]}"
}

bashrc-pre-declare() {
    local -r var=$1
    shift

    local dec; dec=$(declare -p "$var")
    if [[ -z $dec ]]; then
        return 1
    fi

    bashrc-pref "01-vars" '%s\n' "$dec"
}

bashrc-dump-function() {
    local -r fn=$1
    local dec; dec=$(declare -f "$fn")

    if [[ -z $dec ]]; then
        return 1
    fi

    local -r lf=$'\n'
    local IFS=$'\n'
    local -i c=0

    local normalized

    while read -r line; do
        rtrim line
        if (( c == 0 )); then
            if [[ $line == *" ()" ]]; then
                line="${line: 0:-3}() {"
            fi
        elif (( c == 1 )); then
            if [[ $line == '{' ]]; then
                line=""
            fi
        fi

        if [[ -z ${line:-} ]]; then
            continue
        fi

        : $(( c++ ))

        normalized=${normalized:-}${line}${lf}
    done <<< "$dec"

    echo "$normalized"
}

bashrc-pre-function() {
    local -r fn=$1
    local dec; dec=$(bashrc-dump-function "$fn")
    bashrc-pref "02-functions" '%s\n' "$dec"
}

bashrc-var() {
    local -r var=$1
    local -r value=$2

    bashrc-pref "01-vars" '%s=%q\n' "$var" "$value"
}

bashrc-alias() {
    local -r name=$1
    local -r cmd=$2
    bashrc-includef "10-alias" 'alias %s="%s"\n' "$name" "$cmd"
}

bashrc-export-var() {
    local -r name=$1
    local -r value=$2

    bashrc-includef "01-vars" 'export %s=%q\n' "$name" "$value"
}

bashrc-unset-var() {
    local -r name=$1
    bashrc-includef "01-vars" 'unset %s\n' "$name"
}

bashrc-command-exists() {
    command -v "$1" &>/dev/null
}

bashrc-include-function() {
    local -r name=$1

    local body
    if body=$(bashrc-dump-function "$name"); then
        bashrc-includef "function_${name}" '%s\n' "$body"

    else
        echo "function $name not found"
    fi
}

bashrc-include-file() {
    local -r target=$1
    local -r fname=$2
    local -ri notime=${3:-0}

    local short=${fname#"$BUILD_BASHRC_DIR/"}
    short=${short#"$REPO_ROOT/home/.local/bash/"}
    short=${short#"$REPO_ROOT/"}
    short=${short#"$HOME/"}

    local -i is_repo_file=0
    if [[ "$fname" = "${REPO_ROOT}"/* ]]; then
        is_repo_file=1
    fi

    bashrc-append "$target" '# BEGIN: %s\n' "$fname"

    if (( notime != 1 )); then
        bashrc-append "$target" '__rc_timer_start "include(%s)"\n' "$short"
    fi

    if (( is_repo_file == 0 )); then
        printf '# shellcheck disable=all\n' >> "$target"
        printf '\n{\n' >> "$target"
    fi

    cat "$fname" >> "$target"

    if (( is_repo_file == 0 )); then
        printf '\n}\n' >> "$target"
    fi

    if (( notime != 1 )); then
        bashrc-append "$target" '__rc_timer_stop\n'
    fi

    bashrc-append "$target" '# END: %s\n\n' "$fname"
}

bashrc-pre-include-file() {
    local -r fname=$1
    local -r base=${2:-${fname##*/}}

    local -r target=${BUILD_BASHRC_PRE}/${base}

    bashrc-include-file "$target" "$fname" 1
}

bashrc-main-include-file() {
    local -r fname=$1
    local -r base=${2:-${fname##*/}}

    local -r target=${BUILD_BASHRC_INC}/${base}

    bashrc-include-file "$target" "$fname"
}

bashrc-generate-init() {
    if [[ -d $BUILD_BASHRC_DIR ]]; then
        rm -rfv "$BUILD_BASHRC_DIR"
    fi

    reset-facts

    mkdir -vp \
        "$BUILD_BASHRC_INC" \
        "$BUILD_BASHRC_PRE"

    bashrc-includef "10-alias" 'unalias -a\n'
}

bashrc-generate-finalize () {
    touch "$BUILD_BASHRC_FILE"

    shopt -s nullglob

    local f

    bashrc-include-file "$BUILD_BASHRC_FILE" "$REPO_ROOT"/bash/rc_init.bash 1
    bashrc-include-file "$BUILD_BASHRC_FILE" "$REPO_ROOT"/bash/rc_debug.bash 1

    for f in "$BUILD_BASHRC_PRE"/*; do
        bashrc-include-file "$BUILD_BASHRC_FILE" "$f" 1
    done

    bashrc-include-file "$BUILD_BASHRC_FILE" "$REPO_ROOT"/bash/rc_main.bash 1

    for f in "$BUILD_BASHRC_INC"/*; do
        bashrc-include-file "$BUILD_BASHRC_FILE" "$f"
    done

    for f in "$REPO_ROOT"/bash/rc.d/*; do
        bashrc-include-file "$BUILD_BASHRC_FILE" "$f"
    done

    bashrc-include-file "$BUILD_BASHRC_FILE" "$REPO_ROOT"/bash/rc_cleanup.bash 1

    bash -n "$BUILD_BASHRC_FILE" || {
        echo "FATAL: syntax error in generated .bashrc file" >&2
        exit 1
    }

    if bashrc-command-exists shellcheck; then
        shellcheck "$BUILD_BASHRC_FILE" || {
            echo "FATAL: 'shellcheck .bashrc' returned non-zero" >&2
            exit 1
        }
    fi

    install \
        --compare \
        --no-target-directory \
        "$BUILD_BASHRC_FILE" \
        "$HOME/.bashrc"
}
