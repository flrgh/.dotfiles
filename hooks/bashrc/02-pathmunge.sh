#!/usr/bin/env bash

set -euo pipefail

source "$REPO_ROOT"/lib/bash/generate.bash

readonly DEST=path-munge

append() {
    bashrc-pref "$DEST" "$@"
}

add-function() {
    local -r name=$1

    local body
    if body=$(declare -f "$name" 2>/dev/null); then
        append '%s\n' "$body"

    else
        echo "function $name not found"
    fi
}

add-call() {
    bashrc-pre-exec "$DEST" "$@"
}

__rc_have_varsplice=0
if [[ -e $HOME/.local/lib/bash/builtins.bash ]]; then
    source "$HOME/.local/lib/bash/builtins.bash"
    __rc_have_varsplice=${BASH_USER_BUILTINS[varsplice]:-0}
fi

if (( __rc_have_varsplice == 1 )); then
    lib="${BASH_USER_BUILTINS_SOURCE[varsplice]}"
    add-call enable -f "${lib:?empty varsplice lib source}" varsplice
fi

if (( __rc_have_varsplice == 1 )); then
    add-call __rc_debug '__rc_set_path_separator(): using varsplice'

    __rc_set_path_separator() {
        local -r var=${1?var name require}
        local -r sep=${2?separator required}

        varsplice --default -s "$sep" "$var"
    }

else
    declare -A __RC_PATH_SEPARATORS=()
    bashrc-pre-declare "$DEST" -A '__RC_PATH_SEPARATORS=()'

    __rc_set_path_separator() {
        local -r var=${1?var name require}
        local -r sep=${2?separator required}

        __RC_PATH_SEPARATORS["$var"]="$sep"
    }
fi

add-function __rc_set_path_separator

add-call __rc_set_path_separator PATH       ":"
add-call __rc_set_path_separator MANPATH    ":"
add-call __rc_set_path_separator CDPATH     ":"
add-call __rc_set_path_separator LUA_PATH   ";"
add-call __rc_set_path_separator LUA_CPATH  ";"

add-call __rc_set_path_separator EXECIGNORE ":"
add-call __rc_set_path_separator FIGNORE    ":"
add-call __rc_set_path_separator GLOBIGNORE ":"
add-call __rc_set_path_separator HISTIGNORE ":"

if (( __rc_have_varsplice == 1 )); then
    add-call varsplice --normalize PATH
    add-call varsplice --normalize MANPATH
    add-call varsplice --normalize CDPATH
    add-call varsplice --normalize LUA_PATH
    add-call varsplice --normalize LUA_CPATH
fi

if (( __rc_have_varsplice == 1 )); then
    add-call __rc_debug "__rc_add_path(): using varsplice"

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

add-function __rc_add_path

if (( __rc_have_varsplice == 1 )); then
    add-call __rc_debug "__rc_rm_path(): using varsplice"

    __rc_rm_path() {
        __rc_timer_start "__rc_rm_path"
        varsplice --remove "$@"
        __rc_timer_stop
    }

else
    __rc_rm_path() {
        __rc_timer_start "__rc_rm_path"

        local var sep remove

        local arg
        while (( $# > 0 )); do
            local arg=$1
            shift 1

            case $arg in
                --sep)
                    if [[ -z $1 ]]; then
                        __rc_warn "__rc_rm_path(): --sep requires an argument"
                        __rc_timer_stop
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

        local -r current=${!var}

        if [[ -z $current ]]; then
            __rc_timer_stop
            return
        fi

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

add-function __rc_rm_path
