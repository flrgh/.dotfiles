# shellcheck enable=deprecate-which
# shellcheck disable=SC1090
# shellcheck disable=SC1091
# shellcheck disable=SC2059

__RC_START=${EPOCHREALTIME/./}

# must be turned on early
shopt -s extglob

__RC_PID=$$
