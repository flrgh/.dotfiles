export REPO_ROOT=${DOTFILES_REPO_ROOT:?}
export INSTALL_PATH=${DOTFILES_INSTALL_PATH:?}

export BUILD_ROOT=${REPO_ROOT}/build
export BASH_USER_LIB=${REPO_ROOT}/home/.local/lib/bash

source ./home/.local/lib/bash/trace.bash
source ./home/.local/lib/bash/github-helper-token.bash

LOCAL_BIN=$HOME/.local/bin

_prepend_to_PATH() {
    local -r elem=${1:?}
    PATH=${PATH//"$elem":/}
    PATH=${PATH//:"$elem"/}
    PATH=${elem}:${PATH}
}

if [[ -x $LOCAL_BIN/mise ]]; then
    mise=$LOCAL_BIN/mise
    "$mise" reshim
    _prepend_to_PATH "$HOME/.local/share/mise/shims"
fi

_prepend_to_PATH "$LOCAL_BIN"

fatal() {
    echo FATAL: "$@" >&2
    exit 1
}

truthy() {
    if [[ -z ${1:-} ]]; then
        return 2
    fi

    case ${1,,} in
        true|yes|1|on)  return 0 ;;
        false|no|0|off) return 1 ;;
        *)              return 2 ;;
    esac
}

_on_err() {
    trace
    exit 1
}

trap _on_err ERR
