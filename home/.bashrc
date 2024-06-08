# shellcheck enable=deprecate-which

__RC_START=${EPOCHREALTIME/./}

__RC_LOG_DIR="$HOME/.local/var/log"
__RC_LOG_FILE="$__RC_LOG_DIR/bashrc.log"

__rc_log() {
    local -r ctx=$1
    shift

    local -r ts=$EPOCHREALTIME
    local base
    printf -v base '[%(%F %T)T.%s] - (%s) - ' \
        "${ts%.*}" \
        "${ts#*.}" \
        "$ctx"

    local msg
    for msg in "$@"; do
        echo "${base}${msg}"
    done
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

declare -A __RC_DURATION
declare -A __RC_DURATION_US
declare -A __RC_TIMER_START

DEBUG_BASHRC=${DEBUG_BASHRC:-0}

if (( DEBUG_BASHRC > 0 )); then
    mkdir -p "$__RC_LOG_DIR"

    __rc_debug() {
        local -r ctx="${BASH_SOURCE[2]}:${BASH_LINENO[1]} ${FUNCNAME[1]}"
        local msg
        for msg in "$@"; do
            __rc_log "$ctx" "$msg" | tee -a "$__RC_LOG_FILE"
        done
    }

    __rc_timer_start() {
        local -r key=$1
        __RC_TIMER_START[$key]=${EPOCHREALTIME/./}
    }

    __rc_timer_stop() {
        local -r now=${EPOCHREALTIME/./}

        local -r key=$1
        local -r start=${__RC_TIMER_START[$key]}
        local -r duration=$(( now - start ))

        local -r current=${__RC_DURATION_US[$key]:-0}
        local -r total=$(( duration + current ))
        __RC_DURATION_US[$key]=$total

        # reformat from us to ms for display
        __RC_DURATION[$key]=$(( total / 1000 )).$(( total % 1000 ))ms
    }
else
    __rc_debug()    { :; }
    __rc_timer_start() { :; }
    __rc_timer_stop() { :; }
fi

__rc_add_path() {
    local -r p=$1

    if [[ -z $p ]]; then
        __rc_debug "called with empty value"
        return
    fi

    __rc_timer_start "__rc_add_path"

    # default case is PATH, but some other styles (e.g. LUA_PATH) use different
    # separators like `;`
    local -r var=${2:-PATH}
    local -r sep=${3:-:}

    local -r current=${!var}

    __rc_debug "VAR:     ${var@Q}" \
               "CURRENT: ${current@Q}" \
               "SEP:     ${sep@Q}" \
               "NEW:     ${p@Q}"

    if [[ -z $current ]]; then
        __rc_debug "Setting \$${var} to $p"
        declare -g -x "$var"="$p"

    elif ! [[ $current =~ "${sep}"?"$p""${sep}"? ]]; then
        __rc_debug "Prepending $p to \$${var}"
        local new=${p}${sep}${current}
        declare -g -x "$var"="$new"

    else
        :
        __rc_debug "\$${var} already contains $p"
    fi

    __rc_timer_stop "__rc_add_path"
}

__rc_prompt_command_array=0
# as of bash 5.1, PROMPT_COMMAND can be an array, _but_ this was not supported
# by direnv until 2.34.0
if (( BASH_VERSINFO[0] > 5 )) || (( BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 1 )); then
    if __rc_command_exists direnv; then
        __rc_direnv_version=$(direnv --version)
        __rc_direnv_major=${__rc_direnv_version%%.*}
        __rc_direnv_minor=${__rc_direnv_version#[0-9]*.}
        __rc_direnv_minor=${__rc_direnv_minor%%.*}

        if (( __rc_direnv_major > 2 )) || (( __rc_direnv_major == 2 && __rc_direnv_minor >= 34 )); then
            __rc_prompt_command_array=1
        fi
    else
        __rc_prompt_command_array=1
    fi
fi

if (( __rc_prompt_command_array == 1 )); then
    declare -a PROMPT_COMMAND=()
else
    unset PROMPT_COMMAND
fi

__rc_add_prompt_command() {
    local -r cmd=${1?command required}

    if (( __rc_prompt_command_array == 1 )); then
        # prepend for consistency with `__rc_add_path`
        PROMPT_COMMAND=("$cmd" "${PROMPT_COMMAND[@]}")

    else
        __rc_add_path "$cmd" "PROMPT_COMMAND" ";"
    fi
}

__rc_source_file() {
    local -r fname=$1
    local ret
    __rc_timer_start "__rc_source_file"

    if [[ -f $fname || -h $fname ]] && [[ -r $fname ]]; then
        __rc_debug "sourcing file: $fname"
        local -r key="__rc_source_file($fname)"
        __rc_timer_start "$key"

        # shellcheck disable=SC1090
        source "$fname"
        ret=$?

        __rc_timer_stop "$key"
    else
        __rc_debug "$fname does not exist or is not a regular file"
        ret=1
    fi

    __rc_timer_stop "__rc_source_file"

    return $ret
}

__rc_source_dir() {
    local dir=$1
    if ! [[ -d $dir ]]; then
        __rc_debug "$dir does not exist"
        return
    fi

    local -r key="__rc_source_dir($dir)"
    __rc_timer_start "$key"

    local files=("$dir"/*)

    local f
    for f in "${files[@]}"; do
        __rc_source_file "$f"
    done

    __rc_timer_stop "$key"
}

__rc_source_dir "$HOME/.local/bash/rc.d"

if [[ -d $__RC_LOG_DIR ]]; then
    __RC_END=${EPOCHREALTIME/./}
    __RC_TIME=$(( (__RC_END - __RC_START) / 1000 )).$(( (__RC_END - __RC_START) % 1000 ))

    {
        for __rc_key in "${!__RC_DURATION[@]}"; do
            __rc_val=${__RC_DURATION[$__rc_key]}
            printf '%-16s %s\n' "$__rc_val" "$__rc_key"
        done
    } \
        | sort -n -k1 \
        | while read -r line; do
            __rc_debug "$line"
        done

    if (( DEBUG_BASHRC > 0 )); then
        __rc_debug "startup complete in ${__RC_TIME}ms"
    else
        __rc_log \
            "bashrc" \
            "startup complete in ${__RC_TIME}ms" \
        >> "$__RC_LOG_FILE"
    fi
fi

# shellcheck disable=SC2046
unset -v "${!__RC_@}" "${!__rc_@}"
# shellcheck disable=SC2046
unset -f $(compgen -A function __rc_)

# apparently ${!<varname>*} doesn't expand array vars (?!),
# so we'll unset these manually
unset -v __RC_DURATION
unset -v __RC_DURATION_US
unset -v __RC_TIMER_START


# luamake is annoying and tries to add a bash alias for itself every time it runs,
# so I need to leave this here so that it thinks the alias already exists *grumble*
#
# alias luamake=/home/michaelm/.config/nvim/tools/lua-language-server/3rd/luamake/luamake

# nvm is just as dumb as luamake
# export NVM_DIR="$HOME/.config/nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
