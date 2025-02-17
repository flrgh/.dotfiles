if [[ -e $HOME/.config/github/helper-access-token ]]; then
    # shellcheck disable=SC1091
    source "$HOME"/.config/github/helper-access-token
    export GITHUB_USER=${GITHUB_USER:?Expected GITHUB_USER to be defined}
    export GITHUB_TOKEN=${GITHUB_TOKEN:?Expected GITHUB_TOKEN to be defined}
    # compat for other tools
    export GITHUB_API_TOKEN=$GITHUB_TOKEN
fi
