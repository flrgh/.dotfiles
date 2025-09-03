# must be turned on early
shopt -s extglob

__RC_PID=$$

declare -gi __RC_LOGIN_SHELL=0
if [[ $BASHOPTS == *login_shell* ]]; then
    __RC_LOGIN_SHELL=1
fi

declare -gi __RC_INTERACTIVE_SHELL=0
if [[ $- == *i* ]]; then
    __RC_INTERACTIVE_SHELL=1
fi


if [[ -n ${__RC_REPLACED:-} ]]; then
    echo "[replaced bash session ($__RC_REPLACED)]" >&2
fi
