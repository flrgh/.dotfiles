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

__rc_warn() {
    __rc_log "WARN" "$@"
}

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

declare -A __RC_PATH_SEPARATORS=()

__rc_set_path_separator() {
    local -r var=${1?var name require}
    local -r sep=${2?separator required}

    __RC_PATH_SEPARATORS["$var"]="$sep"
}

__rc_set_path_separator PATH      ":"
__rc_set_path_separator MANPATH   ":"
__rc_set_path_separator LUA_PATH  ";"
__rc_set_path_separator LUA_CPATH ";"

__rc_add_path() {
    local -r insert=0
    local -r append=1
    local -r prepend=2

    local -i mode=$insert
    local after
    local before

    local sep

    local args=()

    while (( $# > 0 )); do
        local elem=$1
        shift 1

        case $elem in
            --prepend)
                mode=$prepend
                ;;

            --append)
                mode=$append
                ;;

            --before)
                if [[ -z $1 ]]; then
                    __rc_warn "__rc_add_path(): --before requires an argument"
                    return 1
                fi
                before="$1"
                shift
                ;;

            --after)
                if [[ -z $1 ]]; then
                    __rc_warn "__rc_add_path(): --after requires an argument"
                    return 1
                fi
                after="$1"
                shift
                ;;

            --sep)
                if [[ -z $1 ]]; then
                    __rc_warn "__rc_add_path(): --sep requires an argument"
                    return 1
                fi
                sep="$1"
                shift
                ;;

            *)
                args+=("$elem")
                ;;
        esac
    done

    if [[ -n $before || -n $after ]] && (( mode != insert )); then
        __rc_warn "cannot use --before|--after with --append|--prepend"
        return 1
    fi

    set -- "${args[@]}"

    local -r path=$1
    local -r var=${2:-PATH}

    if [[ -z $path ]]; then
        __rc_debug "called with empty value"
        return
    fi

    if [[ -z $sep ]]; then
        sep="${__RC_PATH_SEPARATORS["$var"]}"

        if [[ -z $sep ]]; then
            __rc_debug "using default path separator (':') for $path"
            sep=":"
        fi
    fi

    # don't insert anything into $PATH before ~/.local/bin by default
    if (( mode == insert )) \
        && [[ -n $before && -n $after ]] \
        && [[ $var == PATH && $path != "$HOME/.local/bin" ]]
    then
        after="$HOME/.local/bin"
    fi

    if [[ -n $after && $after == "$path" ]] \
        || [[ -n $before && $before == "$path" ]]
    then
        __rc_warn "--after|--before used with the same value as the input path ($path)"
        return 1
    fi

    __rc_timer_start "__rc_add_path"

    local -r current=${!var}

    if [[ -z $current ]]; then
        __rc_debug "Setting \$${var} to $path"
        declare -g -x "$var"="$path"
        __rc_timer_stop "__rc_add_path"
        return
    fi

    local -a old
    IFS="${sep}" read -ra old <<<"$current"

    set -- "${old[@]}"

    local -i len=${#old[@]}
    local -i path_offset=-1
    local -i after_offset=-1
    local -i before_offset=-1

    for i in "${!old[@]}"; do
        local elem=${old[$i]}

        # assume no duplicates

        if [[ $elem == "$path" ]]; then
            path_offset=$i

        elif [[ -n $after && $elem == "$after" ]]; then
            after_offset=$i

        elif [[ -n $before && $elem == "$before" ]]; then
            before_offset=$i
        fi
    done

    if (( path_offset > -1 && mode == insert && after_offset < 0 && before_offset < 0 )); then
        __rc_debug "\$${var} already contained $path, no changes"
        # no changes, but ensure the var is exported
        declare -g -x "${var}=${current}"
        __rc_timer_stop "__rc_add_path"
        return
    fi

    local -a new=()

    if [[ -n $after ]]; then
        for (( i = 0; i < len; i++ )); do
            if (( i == path_offset && i < after_offset )); then
                continue
            fi

            new+=( "${old[$i]}" )

            if (( i == after_offset && path_offset < after_offset )); then
                __rc_debug "Inserting $path into \$${var} after $after"
                new+=("$path")
            fi
        done

        # --after appends if $after and $path are not found
        if (( after_offset < 0 && path_offset < 0 )); then
            __rc_debug "Appending $path to \$${var}"
            new+=("$path")
        fi

    elif [[ -n $before ]]; then
        # --before prepends if $path and $before are not found
        if (( before_offset < 0 && path_offset < 0 )); then
            __rc_debug "Prepending $path to \$${var}"
            new+=("$path")
        fi

        for (( i = 0; i < len; i++ )); do
            if (( i == path_offset && path_offset > before_offset )); then
                continue

            elif (( i == before_offset && ( path_offset < 0 || path_offset > i ) )); then
                __rc_debug "Inserting $path into \$${var} before $before"
                new+=("$path")
            fi

            new+=( "${old[$i]}" )
        done

    elif (( mode == prepend )); then
        __rc_debug "Prepending $path to \$${var}"
        new+=("$path")

        for elem in "$@"; do
            if [[ $elem == "$path" ]]; then
                continue
            fi
            new+=("$elem")
        done

    elif (( mode == append )); then
        __rc_debug "Appending $path to \$${var}"

        for elem in "$@"; do
            if [[ $elem == "$path" ]]; then
                continue
            fi
            new+=("$elem")
        done

        new+=("$path")

    elif (( mode == insert )); then
        __rc_debug "Prepending $path to \$${var}"
        new=("$path" "${old[@]}")

    else
        echo "unreachable!"
        exit 1
    fi

    set -- "${new[@]}"
    local first=$1
    shift

    local value
    printf -v value '%s' "$first" "${@/#/$sep}"

    declare -g -x "${var}=${value}"

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
        __rc_add_path "$cmd" "PROMPT_COMMAND" --sep ";"
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
