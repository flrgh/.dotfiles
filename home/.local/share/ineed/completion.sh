#!/usr/bin/env bash

__ineed_completions() {
    local cur prev words cword

    if ((
            BASH_COMPLETION_VERSINFO[0] > 2
            || ( BASH_COMPLETION_VERSINFO[0] >= 2
                 && BASH_COMPLETION_VERSINFO[1] >= 12 )
        ))
    then
        _comp_initialize || return

    else
        _init_completion || return
    fi

    local -r INEED_ROOT="$HOME/.local/share/ineed"

    source "$INEED_ROOT/lib.sh"
    source "$INEED_ROOT/cli.sh"

    _COMMAND=
    _DRIVER=
    _VERSION=
    _FLAGS=()
    _OTHER=()

    #{
    #    echo "----"
    #    for var in ${!COMP@}; do
    #        dump-var "$var"
    #    done

    #    for var in ${!INEED@}; do
    #        dump-var "$var"
    #    done

    #} >> ./log.txt


    if (( ${#COMP_WORDS[@]} == 2 )); then

        if [[ -z $cur ]]; then
            COMPREPLY=( "${INEED_CLI_COMMANDS[@]}" )

        else
            complete-from-commands
        fi

        return
    fi

    for (( i = 1; i < ${#COMP_WORDS[@]}; i++ )); do
        local w=${COMP_WORDS[$i]}

        if [[ -z "$w" ]]; then
            continue

        elif is-command "$w"; then
            _COMMAND=$w
            continue

        elif is-driver "$w"; then
            _DRIVER=$w
            continue

        elif [[ $w =~ ^--? ]]; then
            _FLAGS+=("$w")
            continue

        elif [[ $w == latest || $w =~ ^[0-9.]+$ ]]; then
            _VERSION=$w
            continue
        fi

        _OTHER+=("$w")
    done

    #{
    #    dump-var _COMMAND
    #    dump-var _DRIVER
    #    dump-var _VERSION
    #    dump-var _FLAGS
    #    dump-var _OTHER
    #} >> ./log.txt


    if (( ${#COMP_WORDS[@]} > 2 )); then
        for (( i = ${#COMP_WORDS[@]}; i > 0; i-- )); do
            local word=${COMP_WORDS[$i]}

            if have-completion "$word"; then
                "${word}::complete"
                return
            fi
        done
    fi
}

complete -F __ineed_completions ineed
