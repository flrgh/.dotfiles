bin-path() {
    local -r name=${1?binary name is required}
    local path; path=$(builtin type -P "$name")

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
