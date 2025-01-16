BASH_USER_LIB=${BASH_USER_LIB:-$HOME/.local/lib/bash}
source "$BASH_USER_LIB"/__init.bash
(( BASH_USER_LIB_SOURCED[version]++ == 0 )) || return 0

_version_parse() {
    declare -ga REPLY=(0 0 0 "")

    local v=$1
    if [[ $v =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(.*)$ ]]; then
        REPLY[0]=${BASH_REMATCH[1]}
        REPLY[1]=${BASH_REMATCH[2]}
        REPLY[2]=${BASH_REMATCH[3]}
        REPLY[3]=${BASH_REMATCH[4]}

    elif [[ $v =~ ^([0-9]+)\.([0-9]+)(.*)$ ]]; then
        REPLY[0]=${BASH_REMATCH[1]}
        REPLY[1]=${BASH_REMATCH[2]}
        REPLY[2]=0
        REPLY[3]=${BASH_REMATCH[3]}

    elif [[ $v =~ ^([0-9]+)(.*)$ ]]; then
        REPLY[0]=${BASH_REMATCH[1]}
        REPLY[1]=0
        REPLY[2]=0
        REPLY[3]=${BASH_REMATCH[2]}

    else
        return 1
    fi
}

_version_gt() {
    if (( $# != 8 )); then
        return 127
    fi

    local -ir l_major=$1
    local -ir l_minor=$2
    local -ir l_patch=$3
    local  -r l_extra=$4

    local -ir r_major=$5
    local -ir r_minor=$6
    local -ir r_patch=$7
    local  -r r_extra=$8

    if (( l_major != r_major )); then
        (( l_major > r_major ))
        return $?
    fi

    if (( l_minor != r_minor )); then
        (( l_minor > r_minor ))
        return $?
    fi

    if (( l_patch != r_patch )); then
        (( l_patch > r_patch ))
        return $?
    fi

    if [[ $l_extra != "$r_extra" ]]; then
        [[ -z $l_extra ]] && return 0
        [[ -z $r_extra ]] && return 1
        [[ $l_extra > $r_extra ]] && return 0
    fi

    return 1
}

version-compare() {
    local op
    local -a lv rv

    local -i argc=$#
    case $argc in
        0|1|2)
            return 127
            ;;

        # 1.2.3 gt 4.5.6
        3)
            local -r lhs=${1?lhs version required}
            op=${2?comparison operator required}
            local -r rhs=${3?rhs version required}

            _version_parse "$lhs" || return 127
            lv=("${REPLY[@]}")

            _version_parse "$rhs" || return 127
            rv=("${REPLY[@]}")
            ;;

        # 1 2 3 gt 4 5 6
        7)
            version-compare "$1" "$2" "$3" "" "$4" "$5" "$6" "$7" ""
            return $?
            ;;

        # 1 2 3 foo gt 4 5 6 foo
        9)
            local -i reset=0
            if ! shopt -q extglob; then
                shopt -s extglob
                reset=1
            fi

            local -i ok=0
            if [[ $1/$2/$3/$6/$7/$8 = +([0-9])/+([0-9])/+([0-9])/+([0-9])/+([0-9])/+([0-9]) ]]; then
                ok=1
            fi

            if (( reset == 1 )); then
                shopt -u extglob
            fi

            if (( ok != 1 )); then
                return 127
            fi

            lv=("$1" "$2" "$3" "$4")
            op=$5
            rv=("$6" "$7" "$8" "$9")
            ;;

        # 1.2.3 eq 1 2 3
        # 1 2 eq 1 2 0
        *)
            lv=(0 0 0 "")
            rv=(0 0 0 "")

            local -i i
            for (( i = 0; i < 4; i++ )); do
                case $1 in
                    gt|gte|lt|lte|eq)
                        break
                        ;;
                    *)
                        lv[i]=$1
                        ;;
                esac
                shift || break
            done

            (( i == 0 )) && return 127

            if (( i == 1 )); then
                _version_parse "${lv[0]}" || return 127
                lv=("${REPLY[@]}")
            fi

            op=$1
            shift || return 127

            local -i argc=$#
            for (( i = 0; i < argc; i++ )); do
                rv[i]=$1
                shift || break
            done

            (( i == 0 )) && return 127

            if (( i == 1 )); then
                _version_parse "${rv[0]}" || return 127
                rv=("${REPLY[@]}")
            fi

            version-compare "${lv[@]}" "$op" "${rv[@]}"
            return $?
            ;;
    esac


    local -i eq=0
    if (( lv[0] == rv[0] && lv[1] == rv[1] && lv[2] == rv[2] )) \
        && [[ "${lv[3]}" == "${rv[3]}" ]]
    then
        eq=1
    fi

    case $op in
        gt)
            (( eq == 0 )) && _version_gt "${lv[@]}" "${rv[@]}"
            ;;

        gte)
            (( eq == 1 )) || _version_gt "${lv[@]}" "${rv[@]}"
            ;;

        lt)
            (( eq == 0 )) && ! _version_gt "${lv[@]}" "${rv[@]}"
            ;;

        lte)
            (( eq == 1 )) || ! _version_gt "${lv[@]}" "${rv[@]}"
            ;;

        eq)
            (( eq == 1 ))
            ;;

        *)
            return 127
            ;;
    esac
}
