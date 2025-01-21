# shellcheck enable=deprecate-which
# shellcheck disable=SC1091
# shellcheck disable=SC2059

__RC_START=${EPOCHREALTIME/./}

__RC_DOTFILES="$HOME/git/flrgh/.dotfiles"
if [[ ! -d $__RC_DOTFILES ]]; then
    echo "couldn't locate dotfiles directory ($__RC_DOTFILES)"
    echo "exiting ~/.bashrc early"
    return
fi

# must be turned on early
shopt -s extglob

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

# returns 0 if and only if a function exists
__rc_function_exists() {
    [[ $(type -t "$1") = function ]]
}

# returns 0 if and only if a command exists and is an executable file
# (not a function or alias)
__rc_binary_exists() {
    [[ -n $(type -f -p "$1") ]]
}

__rc_command_exists() {
    local -r cmd=$1
    command -v "$cmd" &> /dev/null
}

__rc_warn() {
    __rc_print "WARN" "$@"
}

declare -A __RC_DURATION
declare -A __RC_DURATION_US
declare -A __RC_TIMER_START

declare -i __RC_TIMED_US_LAST=0
declare -i __RC_TIMED_US=0

declare -i __RC_TIMER_STACK_POS=0
declare -a __RC_TIMER_STACK=()

DEBUG_BASHRC=${DEBUG_BASHRC:-0}
TRACE_BASHRC=${TRACE_BASHRC:-0}

declare __RC_TRACE_FILE
if (( TRACE_BASHRC > 0 )); then
    __RC_TRACE_FILE=${__RC_LOG_DIR}/bashrc.trace.$$.log
    __rc_print "tracing" "Trace logfile: $__RC_TRACE_FILE"
    exec {BASH_XTRACEFD}>"$__RC_TRACE_FILE"
    set -x
fi

if (( DEBUG_BASHRC > 0 )); then
    __rc_debug() {
        local -r ctx="${BASH_SOURCE[2]}:${BASH_LINENO[1]} ${FUNCNAME[1]}"
        __rc_log_and_print "$ctx" "$@"
    }
else
    __rc_debug()    { :; }
    __rc_timer_start() { :; }
    __rc_timer_stop() { :; }
fi
