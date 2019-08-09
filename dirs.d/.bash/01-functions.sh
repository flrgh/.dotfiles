addPath() {
    local -r p=$1
    if ! [[ $PATH =~ :?$p:? ]]; then
        export PATH=${p}:$PATH
    fi
}
