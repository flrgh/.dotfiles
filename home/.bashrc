# shellcheck enable=deprecate-which

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

    __rc_timer_push() {
        local -ri size=${#__RC_TIMER_STACK[@]}
        if (( size == 0 )); then
            __RC_TIMED_US_LAST=${EPOCHREALTIME/./}
        fi

        local -r key=$1

        __RC_TIMER_STACK+=("$key")
    }

    __rc_timer_pop() {
        local -nI dest=$1
        local -ri size=${#__RC_TIMER_STACK[@]}
        if (( size < 1 )); then
            ___rc_debug "timer stack underflow"
            return 1
        fi

        dest=${__RC_TIMER_STACK[-1]}
        unset "__RC_TIMER_STACK[-1]"

        if (( size == 1 )); then
            local -ri now=${EPOCHREALTIME/./}
            local -ri duration=$(( now - __RC_TIMED_US_LAST ))
            __RC_TIMED_US+=$duration
        fi
    }

    __rc_timer_start() {
        local -r key=$1
        local -ri now=${EPOCHREALTIME/./}

        __rc_timer_push "$key"
        __RC_TIMER_START[$key]=$now
    }

    __rc_timer_stop() {
        local -ri now=${EPOCHREALTIME/./}

        local key
        __rc_timer_pop key || return

        local -ri start=${__RC_TIMER_START[$key]:-0}

        if (( start == 0 )); then
            return
        fi

        local -ri duration=$(( now - start ))
        local -ri last=${__RC_DURATION_US[$key]:-0}
        local -ri total=$(( duration + last ))
        __RC_DURATION_US[$key]=$total

        # reformat from us to ms for display
        __RC_DURATION[$key]=$(( total / 1000 )).$(( total % 1000 ))ms
    }
else
    __rc_debug()    { :; }
    __rc_timer_start() { :; }
    __rc_timer_stop() { :; }
fi

__rc_timer_start "check/load varsplice builtin"
__rc_have_varsplice=0
if [[ -e $HOME/.local/lib/bash/builtins.bash ]]; then
    source "$HOME/.local/lib/bash/builtins.bash"
    __rc_have_varsplice=${BASH_USER_BUILTINS[varsplice]:-0}
fi
__rc_timer_stop

__rc_timer_start "define-rc-functions"

declare -A __RC_PATH_SEPARATORS=()

if (( __rc_have_varsplice == 1 )); then
    __rc_debug "__rc_set_path_separator(): using varsplice"

    __rc_set_path_separator() {
        local -r var=${1?var name require}
        local -r sep=${2?separator required}

        varsplice --default -s "$sep" "$var"
    }

else
    __rc_set_path_separator() {
        local -r var=${1?var name require}
        local -r sep=${2?separator required}

        __RC_PATH_SEPARATORS["$var"]="$sep"
    }
fi

__rc_set_path_separator PATH       ":"
__rc_set_path_separator MANPATH    ":"
__rc_set_path_separator CDPATH     ":"
__rc_set_path_separator LUA_PATH   ";"
__rc_set_path_separator LUA_CPATH  ";"

__rc_set_path_separator EXECIGNORE ":"
__rc_set_path_separator FIGNORE    ":"
__rc_set_path_separator GLOBIGNORE ":"
__rc_set_path_separator HISTIGNORE ":"

if (( __rc_have_varsplice == 1 )); then
    varsplice --normalize PATH
    varsplice --normalize MANPATH
    varsplice --normalize CDPATH
    varsplice --normalize LUA_PATH
    varsplice --normalize LUA_CPATH
fi

if (( __rc_have_varsplice == 1 )); then
    __rc_debug "__rc_add_path(): using varsplice"

    __rc_add_path() {
        __rc_timer_start "__rc_add_path"
        varsplice "$@"
        __rc_timer_stop
    }

else
    __rc_add_path() {
        __rc_timer_start

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
                        __rc_timer_stop
                        return 1
                    fi
                    before="$1"
                    shift
                    ;;

                --after)
                    if [[ -z $1 ]]; then
                        __rc_warn "__rc_add_path(): --after requires an argument"
                        __rc_timer_stop
                        return 1
                    fi
                    after="$1"
                    shift
                    ;;

                --sep)
                    if [[ -z $1 ]]; then
                        __rc_warn "__rc_add_path(): --sep requires an argument"
                        __rc_timer_stop
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
            __rc_timer_stop
            return 1
        fi

        set -- "${args[@]}"

        local -r var=${1:-PATH}
        local -r path=$2

        if [[ -z $path ]]; then
            __rc_debug "called with empty value"
            __rc_timer_stop
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
            && [[ -z $before && -z $after ]] \
            && [[ $var == PATH && $path != "$HOME/.local/bin" ]]
        then
            after="$HOME/.local/bin"
        fi

        if [[ $after == "$path" || $before == "$path" ]]; then
            __rc_warn "--after|--before used with the same value as the input path ($path)"
            __rc_timer_stop
            return 1
        fi

        local -r current=${!var}

        if [[ -z $current ]]; then
            __rc_debug "Setting \$${var} to $path"
            declare -g -x "$var"="$path"
            __rc_timer_stop
            return
        fi

        local -a old
        IFS="${sep}" read -ra old <<<"$current"

        set -- "${old[@]}"

        local -i len=${#old[@]}
        local -i path_offset=-1
        local -i after_offset=-1
        local -i before_offset=-1

        local i
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
            __rc_timer_stop
            return
        fi

        local -a new=()
        local i

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

            local elem
            for elem in "$@"; do
                if [[ $elem == "$path" ]]; then
                    continue
                fi
                new+=("$elem")
            done

        elif (( mode == append )); then
            __rc_debug "Appending $path to \$${var}"

            local elem
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

        __rc_timer_stop
    }
fi

if (( __rc_have_varsplice == 1 )); then
    __rc_debug "__rc_rm_path(): using varsplice"

    __rc_rm_path() {
        __rc_timer_start "__rc_rm_path"
        varsplice --remove "$@"
        __rc_timer_stop
    }

else
    __rc_rm_path() {
        local var sep remove

        local arg
        while (( $# > 0 )); do
            local arg=$1
            shift 1

            case $arg in
                --sep)
                    if [[ -z $1 ]]; then
                        __rc_warn "__rc_rm_path(): --sep requires an argument"
                        return 1
                    fi
                    sep="$1"
                    shift
                    ;;

                *)
                    set -- "$arg" "$@"
                    break
                    ;;
            esac
        done

        local -r var=${1:-PATH}
        local -r remove=$2

        if [[ -z $remove ]]; then
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

        local -r current=${!var}

        if [[ -z $current ]]; then
            return
        fi

        __rc_timer_start "__rc_rm_path"

        local -a old new
        IFS="${sep}" read -ra old <<<"$current"

        local -i changed=0

        local -i i
        for i in "${!old[@]}"; do
            local elem=${old[$i]}

            if [[ $elem == "$remove" ]]; then
                __rc_debug "Removing $elem from \$${var} at position #$i"
                changed=1
                continue
            fi

            new+=("$elem")
        done

        if (( changed == 1)); then
            set -- "${new[@]}"
            local first=$1
            shift

            local value
            printf -v value '%s' "$first" "${@/#/$sep}"

            declare -g -x "${var}=${value}"
        else
            __rc_debug "$remove not found in \$${var}, no changes"
        fi

        __rc_timer_stop
    }
fi
__rc_timer_stop

__rc_prompt_command_array=0
# as of bash 5.1, PROMPT_COMMAND can be an array, _but_ this was not supported
# by direnv until 2.34.0
if (( BASH_VERSINFO[0] > 5 )) || (( BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 1 )); then
    __rc_timer_start "direnv-check-version"

    __rc_direnv=$HOME/.local/bin/direnv
    __rc_direnv_min_version=2.34.0
    __rc_direnv_version=

    if [[ -L $__rc_direnv ]]; then
        __rc_direnv=$(realpath "$__rc_direnv")
        __rc_direnv_version=${__rc_direnv%/*}
        __rc_direnv_version=${__rc_direnv_version##*/}
        __rc_debug "direnv version (from vbin): $__rc_direnv_version"

    elif __rc_command_exists direnv; then
        __rc_direnv_version=$(direnv version 2>/dev/null || true)
        __rc_debug "direnv version (from 'direnv version'): $__rc_direnv_version"
    fi

    if [[ -n $__rc_direnv_version ]]; then
        source "$HOME/.local/lib/bash/version.bash"
        if version-compare "$__rc_direnv_version" gte "$__rc_direnv_min_version"; then
           __rc_prompt_command_array=1
        fi
    fi

    __rc_timer_stop
fi

__rc_timer_start "define-rc-functions"
if (( __rc_prompt_command_array == 1 )); then
    declare -a PROMPT_COMMAND=()

    __rc_add_prompt_command() {
        local -r cmd=${1?command required}

        __rc_timer_start "__rc_add_prompt_command($cmd)"

        local -a new=()

        local elem
        for elem in "${PROMPT_COMMAND[@]}"; do
            if [[ $elem == "$cmd" ]]; then
                continue
            fi
            new+=("$elem")
        done

        # prepend for consistency with `__rc_add_path`
        PROMPT_COMMAND=("$cmd" "${new[@]}")

        __rc_timer_stop
    }
else
    unset PROMPT_COMMAND

    __rc_add_prompt_command() {
        local -r cmd=${1?command required}
        __rc_add_path --prepend --sep ";" PROMPT_COMMAND "$cmd"
    }
fi

__rc_source_file() {
    local -r fname=$1
    local ret

    __rc_timer_start "__rc_source_file($fname)"

    if [[ -f $fname || -h $fname ]] && [[ -r $fname ]]; then
        __rc_debug "sourcing file: $fname"

        # shellcheck disable=SC1090
        source "$fname"
        ret=$?
    else
        __rc_debug "$fname does not exist or is not a regular file"
        ret=1
    fi

    __rc_timer_stop

    return $ret
}

__rc_source_dir() {
    local dir=$1
    if ! [[ -d $dir ]]; then
        __rc_debug "$dir does not exist"
        return
    fi

    # nullglob must be set/reset outside of the file-sourcing context, or else
    # it is impossible for any sourced file to toggle its value
    local -i reset=0
    if ! shopt -q nullglob; then
        shopt -s nullglob
        reset=1
    fi

    local -a files=("$dir"/*)

    if (( reset == 1 )); then
        shopt -u nullglob
    fi

    local f
    for f in "${files[@]}"; do
        __rc_source_file "$f"
    done
}
__rc_timer_stop

__rc_source_dir "$HOME/.local/bash/rc.d"
__rc_source_dir "$HOME/.local/bash/gen.d"
__rc_source_dir "$HOME/.local/bash/overrides.d"

if (( ${#__RC_TIMER_STACK[@]} > 0 )); then
    __rc_warn "timer strack should be empty, but: ${__RC_TIMER_STACK[*]}"
fi

__RC_END=${EPOCHREALTIME/./}
__RC_TIME_US=$(( __RC_END - __RC_START ))
__RC_TIME=$(( __RC_TIME_US / 1000 )).$(( __RC_TIME_US % 1000 ))

if (( DEBUG_BASHRC > 0 )); then
    {
        for __rc_key in "${!__RC_DURATION[@]}"; do
            __rc_time=${__RC_DURATION[$__rc_key]}
            printf '%-16s %s\n' "$__rc_time" "$__rc_key"
        done
    } \
        | sort -n -k1 \
        | while read -r line; do
            __rc_debug "$line"
        done

    __rc_untimed_us=$(( __RC_TIME_US - __RC_TIMED_US ))
    if (( __rc_untimed_us > 0 )); then
        __rc_timed=$(( __RC_TIMED_US / 1000 )).$(( __RC_TIMED_US % 1000 ))
        __rc_untimed=$(( __rc_untimed_us / 1000 )).$(( __rc_untimed_us % 1000 ))
        __rc_debug "accounted time: ${__rc_timed}ms"
        __rc_debug "unaccounted time: ${__rc_untimed}ms"
    fi

    __rc_debug "startup complete in ${__RC_TIME}ms"
else
    __rc_log \
        "bashrc" \
        "startup complete in ${__RC_TIME}ms"
fi

if (( TRACE_BASHRC > 0 )); then
    set +x

    if (( BASH_XTRACEFD > 0 )); then
        exec {BASH_XTRACEFD}>&-
    fi

    unset BASH_XTRACEFD
fi

if (( __RC_LOG_FD > 0 )); then
    exec {__RC_LOG_FD}>&-
fi

# shellcheck disable=SC2046
unset -v "${!__RC_@}" "${!__rc_@}"
# shellcheck disable=SC2046
unset -f $(compgen -A function __rc_)

# apparently ${!<varname>*} doesn't expand associative array vars (?!),
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
