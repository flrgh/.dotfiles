# This is for functions that will be available to the shell after
# .bashrc is sourced
#
# Functions used only while sourcing .bashrc should go in .bashrc

:q() {
    echo "hey you're not in vim anymore, but I can exit the shell for you..."
    sleep 0.75 && exit
}

extract() {
    __function_dispatch "$@"
}

strip-whitespace() {
    __function_dispatch "$@"
}

bin-path() {
    __function_dispatch "$@"
}
alias which="bin-path"

dump-array() {
    __function_dispatch "$@"
}

complete -A arrayvar dump-array

dump-var() {
    __function_dispatch "$@"
}

complete -A variable dump-var

dump-prefix() {
    local arg v
    for arg in "$@"; do
        for v in $(compgen -v "$arg"); do
            dump-var "$v"
        done
    done
}

dump-exported() {
    local v
    for v in $(compgen -e); do
        dump-var "$v"
    done
}


complete -A variable dump-prefix

dump-matching() {
    local -r pat=${1?pattern or substring required}

    local v
    for var in $(compgen -v); do
        if [[ $var = *${pat}* ]]; then
            dump-var "$var"
        fi
    done
}
