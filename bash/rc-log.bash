__RC_PID=$$
__RC_LOG_DIR="$HOME/.local/var/log"
__RC_LOG_FILE="$__RC_LOG_DIR/bashrc.log"
__RC_LOG_FD=0

[[ -d $__RC_LOG_DIR ]] || mkdir -p "$__RC_LOG_DIR"
exec {__RC_LOG_FD}>>"$__RC_LOG_FILE"

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

__rc_print() {
    local -r ctx=$1
    shift

    __rc_fmt "$ctx"
    printf "$REPLY" "$@"
}

__rc_log() {
    __rc_print "$@" >&"$__RC_LOG_FD"
}

__rc_log_and_print() {
    local -r ctx=$1
    shift

    __rc_fmt "$ctx"
    printf "$REPLY" "$@" >&"$__RC_LOG_FD"
    printf "$REPLY" "$@"
}

__rc_warn() {
    __rc_print "WARN" "$@"
}
