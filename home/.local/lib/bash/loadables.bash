BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}
source "$BASH_USER_LIB"/__init.bash
(( BASH_USER_LIB_SOURCED[loadables]++ == 0 )) || return 0

# no compat shim for sleep
sleep() {
    enable sleep &>/dev/null || true
    unset -f sleep
    sleep "$@"
}

mkdir() {
    unset -f mkdir

    if ! enable mkdir &>/dev/null; then
        mkdir "$@"
        return $?
    fi

    enable -n mkdir

    mkdir() {
        local -a oargs=("$@")
        local -a args=()

        local arg
        while (( $# > 0 )); do
            arg=$1
            shift

            case $arg in
                -p|--parents)
                    args+=(-p)
                    ;;

                -m|--mode)
                    args+=(-m)
                    ;;

                --mode=*)
                    args+=(-m "${arg#*=}")
                    ;;

                --)
                    args+=(-- "$@")
                    break
                    ;;

                -*)
                    command mkdir "${oargs[@]}"
                    return $?
                    ;;

                *)
                    args+=("$arg")
                    ;;
            esac
        done

        builtin mkdir "${args[@]}"
    }

    mkdir "$@"
}

head() {
    unset -f head

    if ! enable head &>/dev/null; then
        head "$@"
        return $?
    fi

    enable -n head

    head() {
        local -a oargs=("$@")
        local -a args=()

        local arg lines
        while (( $# > 0 )); do
            arg=$1
            shift

            case $arg in
                -n|--lines)
                    shift
                    lines=${1:-}
                    if [[ ${lines:-} == [0-9]* ]]; then
                        args+=(-n "$lines")
                        shift
                    else
                        command head "${oargs[@]}"
                        return $?
                    fi
                    ;;

                --lines=*)
                    local lines=${arg#*=}
                    if [[ ${lines:-} == [0-9]* ]]; then
                        args+=(-n "$lines")
                    else
                        command head "${oargs[@]}"
                        return $?
                    fi
                    ;;

                --)
                    args+=(-- "$@")
                    break
                    ;;

                -*)
                    command head "${oargs[@]}"
                    return $?
                    ;;

                *)
                    args+=("$arg")
                    ;;
            esac
        done

        builtin head "${args[@]}"
    }

    head "$@"
}

ln() {
    unset -f ln

    if ! enable ln &>/dev/null; then
        ln "$@"
        return $?
    fi

    enable -n ln

    ln() {
        local -a oargs=("$@")
        local -a args=()

        local arg
        while (( $# > 0 )); do
            arg=$1
            shift

            case $arg in
                -n|--no-dereference)
                    args+=(-n)
                    ;;

                -f|--force)
                    args+=(-f)
                    ;;

                -s|--symbolic)
                    args+=(-s)
                    ;;

                --)
                    args+=(-- "$@")
                    break
                    ;;

                -*)
                    command ln "${oargs[@]}"
                    return $?
                    ;;

                *)
                    args+=("$arg")
                    ;;
            esac
        done

        builtin ln "${args[@]}"
    }

    ln "$@"
}
