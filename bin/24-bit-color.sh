#!/bin/bash

# 2024 - flrg - yanked and adapted from:
# https://raw.githubusercontent.com/JohnMorales/dotfiles/master/colors/24-bit-color.sh
#
# Original docstring:
#
# This file was originally taken from iterm2 https://github.com/gnachman/iTerm2/blob/master/tests/24-bit-color.sh
#
#   This file echoes a bunch of 24-bit color codes
#   to the terminal to demonstrate its functionality.
#   The foreground escape sequence is ^[38;2;<r>;<g>;<b>m
#   The background escape sequence is ^[48;2;<r>;<g>;<b>m
#   <r> <g> <b> range from 0 to 255 inclusive.
#   The escape sequence ^[0m returns output to default

setBackgroundColor() {
    printf '\x1b[48;2;%s;%s;%sm' "$1" "$2" "$3"
}

resetOutput() {
    printf "\x1b[0m\n"
}

# Gives a color $1/255 % along HSV
# Who knows what happens when $1 is outside 0-255
rainbowColor() {
    local arg=$1

    local h=$(( arg / 43 ))
    local f=$(( arg - 43 * h ))
    local t=$(( f * 255 / 43 ))
    local q=$(( 255 - t ))

    local r g b
    case "$h" in
        0)
            r=255
            g=$t
            b=0
            ;;
        1)
            r=$q
            g=255
            b=0
            ;;
        2)
            r=0
            g=255
            b=$t
            ;;
        3)
            r=0
            g=$q
            b=255
            ;;
        4)
            r=$t
            g=0
            b=255
            ;;
        5)
            r=255
            g=0
            b=$q
            ;;
        *)
            echo "UNREACHABLE!"
            exit 1
            ;;
    esac

    setBackgroundColor "$r" "$g" "$b"
}

for i in {0..127}; do
    setBackgroundColor "$i" 0 0
    printf " "
done
resetOutput

for i in {255..128}; do
    setBackgroundColor "$i" 0 0
    printf " "
done
resetOutput

for i in {0..127}; do
    setBackgroundColor 0 "$i" 0
    printf " "
done
resetOutput

for i in {255..128}; do
    setBackgroundColor 0 "$i" 0
    printf " "
done
resetOutput

for i in {0..127}; do
    setBackgroundColor 0 0 "$i"
    printf " "
done
resetOutput

for i in {255..128}; do
    setBackgroundColor 0 0 "$i"
    printf " "
done
resetOutput

for i in {0..127}; do
    rainbowColor "$i"
    printf " "
done
resetOutput

for i in {255..128}; do
    rainbowColor "$i"
    printf " "
done
resetOutput
