export REPO_ROOT=${REPO_ROOT:?REPO_ROOT undefined}
export INSTALL_PATH=${INSTALL_PATH:?INSTALL_PATH undefined}

export BUILD_ROOT=${REPO_ROOT}/build
export BASH_USER_LIB=${REPO_ROOT}/home/.local/lib/bash

source ./home/.local/lib/bash/trace.bash

LOCAL_BIN=$HOME/.local/bin
if [[ $PATH != "$LOCAL_BIN":* ]]; then
    PATH=${LOCAL_BIN}:${PATH}
fi

if command -v mise &>/dev/null; then
    mise reshim
    shims=$HOME/.local/share/mise/shims
    if [[ $PATH != *:"$shims":* ]]; then
        PATH=${PATH#"$LOCAL_BIN":}
        PATH=${LOCAL_BIN}:${shims}:${PATH}
    fi
fi

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
