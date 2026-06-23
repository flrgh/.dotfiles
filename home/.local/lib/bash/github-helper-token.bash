_TOKEN=$(secrets get --cache bws://main/github-helper-token)
if [[ -n ${_TOKEN:-} ]]; then
    export GITHUB_USER=flrgh
    export GITHUB_TOKEN="$_TOKEN"
    # compat for other tools
    export GITHUB_API_TOKEN=$GITHUB_TOKEN
    unset _TOKEN
fi
