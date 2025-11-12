declare -g __GIT_INFO=.git/info
declare -g __GIT_EXCLUDE=.git/info/exclude

git::assert::repo() {
    local -r dir=${1:-"$PWD"}

    if [[ ! -d "$dir"/.git/info ]]; then
        fatal "not a git repository"
    fi
}

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

    git::assert::repo

    if [[ ! -e $__GIT_EXCLUDE ]] || ! grep -qxF "$pat" "$__GIT_EXCLUDE"; then
        git ignore --private "$pat"
    fi

    watch::file "$__GIT_EXCLUDE"
}

# remove a repository-local gitignore pattern
git::unignore() {
    local -r pat=${1:?pattern required}

    git::assert::repo

    if [[ -e $__GIT_EXCLUDE ]] && grep -qxF "$pat" "$__GIT_EXCLUDE"; then
        log::status "removing '$pat' from $__GIT_EXCLUDE"

        local tmp; tmp=$(mktemp)
        grep -vxF "$pat" "$__GIT_EXCLUDE" > "$tmp"
        cat "$tmp" > "$__GIT_EXCLUDE"
        rm "$tmp"
    fi
}
