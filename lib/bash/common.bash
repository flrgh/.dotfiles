export REPO_ROOT=${REPO_ROOT:?REPO_ROOT undefined}
export INSTALL_PATH=${INSTALL_PATH:?INSTALL_PATH undefined}

export BUILD_ROOT=${REPO_ROOT}/build
export BASH_USER_LIB=${REPO_ROOT}/home/.local/lib/bash

LOCAL_BIN=$HOME/.local/bin
if [[ $PATH != "$LOCAL_BIN":* ]]; then
    export PATH=${LOCAL_BIN}:${PATH}
fi
