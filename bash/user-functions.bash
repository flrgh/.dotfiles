# This is for functions that will be available to the shell after
# .bashrc is sourced
#
# Functions used only while sourcing .bashrc should go in .bashrc

:q() {
    echo "hey you're not in vim anymore, but I can exit the shell for you..."
    sleep 0.75 && exit
}

alias which="bin-path"

complete -A arrayvar dump-array
complete -A variable dump-var
complete -A variable dump-prefix
