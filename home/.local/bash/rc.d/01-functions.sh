# This is for functions that will be available to the shell after
# .bashrc is sourced
#
# Functions used only while sourcing .bashrc should go in .bashrc

extract() {
    if [[ -z $1 ]]; then
        echo "usage: extract <filename>"
        return 1
    fi

    if ! test -f "$1"; then
        echo "'$1' is not a valid file"
        return 1
    fi

    case $1 in
        *.tar.bz2)   tar xjf "$1"     ;;
        *.tar.gz)    tar xzf "$1"     ;;
        *.tar.xz)    tar xf "$1"      ;;
        *.bz2)       bunzip2 "$1"     ;;
        *.rar)       rar x "$1"       ;;
        *.gz)        gunzip "$1"      ;;
        *.tar)       tar xf "$1"      ;;
        *.tbz2)      tar xjf "$1"     ;;
        *.tgz)       tar xzf "$1"     ;;
        *.zip)       unzip "$1"       ;;
        *.Z)         uncompress "$1"  ;;
        *.7z)        7z x "$1"        ;;
        *)           echo "'$1' cannot be extracted via extract()"
                     return 1
                     ;;
    esac
}

dump-array() {
    local -r name=$1
    local -rn ref=$1

    for i in "${!ref[@]}"; do
        local fq="${name}[$i]"

    printf "%-32s => %q\n" \
            "$fq" \
            "${ref[$i]}"
    done
}

complete -A arrayvar dump-array

dump-var() {
    local -r name=$1
    if [[ -z $name ]]; then
        for v in $(compgen -v); do
            dump-var "$v"
        done
        return
    fi

    local -rn ref=$1

    local -r dec=${ref@A}

    local -r pat="declare -(a|A)"

    if [[ $dec =~ $pat ]]; then
        dump-array "$name"
        return
    fi

    printf "%-32s => %q\n" \
        "$name" \
        "$ref"
}

complete -A variable dump-var
