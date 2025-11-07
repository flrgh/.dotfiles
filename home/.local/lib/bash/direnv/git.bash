# set/override a specific git configuration item
git::config::set() {
    local -r key=${1?key required}
    local -r value=${2?value required}

    local -i count=${GIT_CONFIG_COUNT:-0}

    export "GIT_CONFIG_KEY_${count}=${key}"
    export "GIT_CONFIG_VALUE_${count}=${value}"

    GIT_CONFIG_COUNT=$(( count + 1 ))
    export GIT_CONFIG_COUNT
}

# add a repository-local gitignore pattern
git::ignore() {
    local -r pat=${1:?pattern required}

    local -r exclude=.git/info/exclude
    if [[ ! -d .git/info ]]; then
        fatal "not a git repository"
    fi

    if [[ ! -e $exclude ]] || ! grep -qxF "$pat" "$exclude"; then
        git ignore --private "$pat"
    fi

    watch::file "$exclude"
}
