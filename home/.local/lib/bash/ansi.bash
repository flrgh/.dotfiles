# ansi escape code constants and helpers

BASH_USER_LIB=${BASH_USER_LIB-$HOME/.local/lib/bash}

# shellcheck source=home/.local/lib/bash/array.bash
source "$BASH_USER_LIB"/array.bash

# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR

# Character sequences of the form $'string' are treated as a special variant of
# single quotes. The sequence expands to string, with backslash-escaped
# characters in string replaced as specified  by the ANSI C standard. Backslash
# escape sequences, if present, are decoded as follows:
#
#   \a     alert (bell)
#   \b     backspace
#   \e
#   \E     an escape character
#   \f     form feed
#   \n     new line
#   \r     carriage return
#   \t     horizontal tab
#   \v     vertical tab
#   \\     backslash
#   \'     single quote
#   \"     double quote
#   \?     question mark
#   \nnn   the eight-bit character whose value is the octal value `nnn`
#          (one to three octal digits)
#   \xHH   the eight-bit character whose value is the hexadecimal value `HH`
#          (one or two hex digits)
#   \uHHHH the Unicode (ISO/IEC 10646) character whose value is the hexadecimal
#          value `HHHH` (one to four hex digits)
#   \UHHHHHHHH
#          the Unicode (ISO/IEC 10646) character whose value is the hexadecimal
#          value `HHHHHHHH` (one to eight hex digits)
#   \cx    a control-x character

declare -g ANSI_ESC=$'\e'
declare -g ANSI_CSI="${ANSI_ESC}["

declare -g ANSI_SGR_FUNCNAME=m
declare -g ANSI_SGR_SEPARATOR=";"

declare -g -i ANSI_SGR_RESET=0

declare -g -A ANSI_MODE_SET=(
    [reset]=0
    [bold]=1
    [dim]=2
    [italic]=3
    [underline]=4
    [blink]=5
    [invert]=7
    [hidden]=8
    [strikethrough]=9
)

declare -g -A ANSI_MODE_RESET=(
    [bold]=22
    [dim]=22
    [italic]=23
    [underline]=24
    [blink]=25
    [invert]=27
    [hidden]=28
    [strikethrough]=29
)

declare -g -A ANSI_FG_COLORS=(
    [black]=30 [grey]=90 [gray]=90

    [red]=31 [bright-red]=91

    [green]=32 [bright-green]=92

    [yellow]=33 [bright-yellow]=93

    [blue]=34 [bright-blue]=94

    [magenta]=35 [bright-magenta]=95

    [cyan]=36 [bright-cyan]=96

    [white]=37 [bright-white]=97

    [default]=39
)

declare -g -A ANSI_BG_COLORS=(
    [black]=40 [gray]=100 [grey]=100

    [red]=41 [bright-red]=101

    [green]=42 [bright-green]=102

    [yellow]=43 [bright-yellow]=103

    [blue]=44 [bright-blue]=104

    [magenta]=45 [bright-magenta]=105

    [cyan]=46 [bright-cyan]=46

    [white]=47 [bright-white]=107

    [default]=49
)

declare +i -g ANSI_RGB_FG='38;2'
declare +i -g ANSI_RGB_BG='48;2'
declare -gi ANSI_RGB_SUPPORT=0

if [[ $COLORTERM = *truecolor* || $COLORTERM = *24bit* ]]; then
    ANSI_RGB_SUPPORT=1
    #ANSI_FG_COLORS[bright-white]="${ANSI_RGB_FG};255;255;255"
fi

__is_rgb() {
    if (( $# != 3 )); then
        return 1
    fi

    for c in "$@"; do
        if [[ $c != +([0-9]) ]]; then
            return 1
        fi

        if (( c < 0 || c > 255 )); then
            return 1
        fi
    done

    return 0
}

ansi-style() {
    local elems=()

    local opt arg
    local mode
    local reset=0
    local destvar
    local prefix suffix
    local color

    # reset
    if [[ -n ${destvar:-} ]]; then
        printf -v "$destvar" ''
    fi

    while (( $# > 0 )); do
        opt=$1
        shift

        case "$opt" in
            -v)
                destvar=${1:?variable name required}
                shift
                ;;

            --reset)
                reset=1
                ;;

            --bg)
                if __is_rgb "$1" "$2" "$3"; then
                    elems+=("$ANSI_RGB_BG" "$1" "$2" "$3")
                    shift 3
                    continue
                fi

                color=${1:?color name required}
                shift

                color=${ANSI_BG_COLORS[$color]:?unknown background color: $color}
                elems+=("$color")
                ;;

            --black|--gray|--grey|--red|--green|--yellow|--blue|--magenta|--cyan|--white)
                color=${opt##"--"}
                color=${ANSI_FG_COLORS[$color]:?unreachable}
                elems+=("$color")
                ;;

            --bright-red|--bright-green|--bright-yellow|--bright-blue|--bright-magenta|--bright-cyan|--bright-white)
                color=${opt##"--"}
                color=${ANSI_FG_COLORS[$color]:?unreachable}
                elems+=("$color")
                ;;


            --fg|--color)
                if __is_rgb "$1" "$2" "$3"; then
                    elems+=("$ANSI_RGB_FG" "$1" "$2" "$3")
                    shift 3
                    continue
                fi

                color=${1:?color name required}
                shift

                color=${ANSI_FG_COLORS[$color]:?unknown foreground color: $color}
                elems+=("$color")
                ;;

            --bold|--italic|--dim|--underline|--blink|--strikethrough)
                mode=${opt##"--"}
                mode=${ANSI_MODE_SET[$mode]:?unreachable}
                elems+=("$mode")
                ;;

            --no-bold|--no-italic|--no-dim|--no-underline|--no-blink|--no-strikethrough)
                mode=${opt##"--no-"}
                mode=${ANSI_MODE_RESET[$mode]:?unreachable}
                elems+=("$mode")
                ;;

            --rgb|--rgb-fg)
                if __is_rgb "$1" "$2" "$3"; then
                    elems+=("$ANSI_RGB_FG" "$1" "$2" "$3")
                    shift 3
                else
                    return 1
                fi
                ;;

            --rgb-bg)
                if __is_rgb "$1" "$2" "$3"; then
                    elems+=("$ANSI_RGB_BG" "$1" "$2" "$3")
                    shift 3
                else
                    return 1
                fi
                ;;

            --prefix)
                prefix=${1:?value required}
                shift
                ;;

            --suffix)
                suffix=${1:?value required}
                shift
                ;;
        esac
    done

    if (( reset == 1 )); then
        elems=("$ANSI_SGR_RESET" "${elems[@]}")
    fi

    local __ansi_joined
    array-join-var __ansi_joined "$ANSI_SGR_SEPARATOR" "${elems[@]}"

    local __ansi_result
    printf -v __ansi_result '%s%s%s%s%s' \
        "${prefix:-}" \
        "$ANSI_CSI" \
        "$__ansi_joined" \
        "$ANSI_SGR_FUNCNAME" \
        "${suffix:-}"

    if [[ -n ${destvar:-} ]]; then
        printf -v "$destvar" '%s' "$__ansi_result"
        return
    fi

    printf '%s' "$__ansi_result"
}
