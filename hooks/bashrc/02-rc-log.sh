#!/usr/bin/env bash

set -euo pipefail

source ./lib/bash/generate.bash
source ./lib/bash/facts.bash

LOG_DIR="$HOME/.local/var/log"

rc-new-workfile "$RC_DEP_LOG"
rc-workfile-add-dep "$RC_DEP_ENV"

rc-workfile-var __RC_LOG_DIR "$LOG_DIR"
rc-workfile-var __RC_LOG_FILE "$LOG_DIR/bashrc.log"
rc-workfile-var __RC_LOG_FD 0

rc-workfile-append '%s\n'

__rc_log_init() {
    [[ -d $__RC_LOG_DIR ]] || mkdir -p "$__RC_LOG_DIR"
    exec {__RC_LOG_FD}>>"$__RC_LOG_FILE"
}

rc-workfile-add-function __rc_log_init
rc-workfile-add-exec __rc_log_init

__rc_fmt() {
    local -r ctx=$1

    local -r ts=$EPOCHREALTIME
    local -r t_sec=${ts%.*}
    local -r t_ms=${ts#*.}

    declare -g REPLY

    printf -v REPLY '[%(%F %T)T.%s] %s (%s) - %%s\n' \
        "$t_sec" \
        "${t_ms:0:3}" \
        "$__RC_PID" \
        "$ctx"
}

rc-workfile-add-function __rc_fmt

__rc_print() {
    local -r ctx=$1
    shift

    __rc_fmt "$ctx"
    printf "$REPLY" "$@"
}
rc-workfile-add-function __rc_print

__rc_log() {
    __rc_print "$@" >&"$__RC_LOG_FD"
}
rc-workfile-add-function __rc_log

__rc_log_and_print() {
    local -r ctx=$1
    shift

    __rc_fmt "$ctx"
    printf "$REPLY" "$@" >&"$__RC_LOG_FD"
    printf "$REPLY" "$@"
}
rc-workfile-add-function __rc_log_and_print

__rc_warn() {
    __rc_print "WARN" "$@"
}

rc-workfile-add-function __rc_warn

rc-workfile-close
