addPath() {
    local -r p=$1
    if ! [[ $PATH =~ :?$p:? ]]; then
        _debug_rc "Prepending $p to \$PATH"
        export PATH=${p}:$PATH
    fi
}
