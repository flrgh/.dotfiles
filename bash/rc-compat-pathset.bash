declare -A __RC_PATH_SEPARATORS=()

__rc_set_path_separator() {
    local -r var=${1?var name require}
    local -r sep=${2?separator required}

    __RC_PATH_SEPARATORS["$var"]="$sep"
}

__rc_set_path_separator PATH       ":"
__rc_set_path_separator MANPATH    ":"
__rc_set_path_separator CDPATH     ":"
__rc_set_path_separator LUA_PATH   ";"
__rc_set_path_separator LUA_CPATH  ";"
__rc_set_path_separator EXECIGNORE ":"
__rc_set_path_separator FIGNORE    ":"
__rc_set_path_separator GLOBIGNORE ":"
__rc_set_path_separator HISTIGNORE ":"

__rc_add_path() {
    timer start "__rc_add_path"

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
                    timer stop
                    return 1
                fi
                before="$1"
                shift
                ;;

            --after)
                if [[ -z $1 ]]; then
                    __rc_warn "__rc_add_path(): --after requires an argument"
                    timer stop
                    return 1
                fi
                after="$1"
                shift
                ;;

            --sep)
                if [[ -z $1 ]]; then
                    __rc_warn "__rc_add_path(): --sep requires an argument"
                    timer stop
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
        timer stop
        return 1
    fi

    set -- "${args[@]}"

    local -r var=${1:-PATH}
    local -r path=$2

    if [[ -z $path ]]; then
        __rc_debug "called with empty value"
        timer stop
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
        timer stop
        return 1
    fi

    local -r current=${!var}

    if [[ -z $current ]]; then
        __rc_debug "Setting \$${var} to $path"
        declare -g -x "$var"="$path"
        timer stop
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
        timer stop
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

    timer stop
}

__rc_rm_path() {
    timer start "__rc_rm_path"

    local var sep remove

    local arg
    while (( $# > 0 )); do
        local arg=$1
        shift 1

        case $arg in
            --sep)
                if [[ -z $1 ]]; then
                    __rc_warn "__rc_rm_path(): --sep requires an argument"
                    timer stop
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
        timer stop
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
        timer stop
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

    timer stop
}
