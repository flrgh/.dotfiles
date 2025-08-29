if (( BASH_USER_MODERN == 1 )); then
    __type_P() {
        path=${ builtin type -P "$1";}
    }
else
    __type_P() {
        path=$(builtin type -P "$1")
    }
fi


bin-path() {
    local -r name=${1?binary name is required}

    local path; __type_P "$name"

    if [[ -z ${path:-} ]]; then
        return 1
    fi

    local -r mise=$HOME/.local/bin/mise
    local -r shim=$HOME/.local/share/mise/shims/${name}

    # resolve mise shim
    if [[ $name != "mise" && $path == "$shim" && -x $mise ]]; then
        local which; which=$("$mise" which "$name")
        path=${which:-"$path"}
    fi

    # `mise which $name` might still return a symlink
    command realpath "$path"
}
