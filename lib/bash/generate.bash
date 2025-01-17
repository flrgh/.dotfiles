source "$REPO_ROOT"/lib/bash/common.bash

export BUILD_BASHRC_DIR=${BUILD_ROOT:?BUILD_ROOT undefined}/bashrc

export BUILD_BASHRC_INC=$BUILD_BASHRC_DIR/rc.d
export BUILD_BASHRC_PRE=$BUILD_BASHRC_DIR/rc.pre.d
export BUILD_BASHRC_FILE=$BUILD_BASHRC_DIR/.bashrc

bashrc-append() {
    local -r name=$1
    shift
    printf -- "$@" | tee -a "$name"
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
    local -r name=$1
    shift

    bashrc-pref "$name" 'declare %s %s\n' "$@"
}

bashrc-var() {
    local -r var=$1
    local -r value=$2

    bashrc-pref "var_${var}" '%s=%q\n' "$var" "$value"
}

bashrc-alias() {
    local -r name=$1
    local -r cmd=$2
    bashrc-includef "10-alias" 'alias %s="%s"\n' "$name" "$cmd"
}

bashrc-export-var() {
    local -r name=$1
    local -r value=$2

    bashrc-includef "export_${name}" 'export %s=%q\n' "$name" "$value"
}

bashrc-unset-var() {
    local -r name=$1
    bashrc-includef "unset_${name}" 'unset %s\n' "$name"
}

bashrc-command-exists() {
    command -v "$1" &>/dev/null
}

bashrc-source-file() {
    local -r fname=$1
    local base; base=$(basename "$fname")
    bashrc-includef "source_${base}" '__rc_source_file %q\n' "$fname"
}

bashrc-source-file-if-exists() {
    local -r fname=$1
    if [[ ! -e $fname ]]; then
        echo "not including $fname (not found)"
        return
    fi

    bashrc-source-file "$fname"
}

bashrc-include-function() {
    local -r name=$1

    local body
    if body=$(declare -f "$name" 2>/dev/null); then
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

    bashrc-append "$target" '# BEGIN: %s\n' "$fname"

    if (( notime != 1 )); then
        bashrc-append "$target" '__rc_timer_start "include(%s)"\n' "$short"
    fi

    tee -a "$target" < "$fname"

    if (( notime != 1 )); then
        bashrc-append "$target" '__rc_timer_stop\n'
    fi

    bashrc-append "$target" '# END: %s\n\n' "$fname"
}

bashrc-generate-init() {
    if [[ -d $BUILD_BASHRC_DIR ]]; then
        rm -rfv "$BUILD_BASHRC_DIR"
    fi

    mkdir -vp "$BUILD_BASHRC_INC" "$BUILD_BASHRC_PRE"

    bashrc-includef "10-alias" 'unalias -a\n'
}

bashrc-generate-finalize () {
    touch "$BUILD_BASHRC_FILE"

    shopt -s nullglob

    local f

    bashrc-include-file "$BUILD_BASHRC_FILE" "$REPO_ROOT"/bash/rc_init.bash 1

    for f in "$BUILD_BASHRC_PRE"/*; do
        bashrc-include-file "$BUILD_BASHRC_FILE" "$f"
    done

    bashrc-include-file "$BUILD_BASHRC_FILE" "$REPO_ROOT"/bash/rc_main.bash 1

    for f in "$BUILD_BASHRC_INC"/*; do
        bashrc-include-file "$BUILD_BASHRC_FILE" "$f"
    done

    for f in "$REPO_ROOT"/bash/rc.d/*; do
        bashrc-include-file "$BUILD_BASHRC_FILE" "$f"
    done

    bashrc-include-file "$BUILD_BASHRC_FILE" "$REPO_ROOT"/bash/rc_cleanup.bash 1

    cat "$BUILD_BASHRC_FILE" > "$HOME/.bashrc"
}
