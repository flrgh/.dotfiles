#!/usr/bin/env bash

set -euo pipefail

source ./lib/bash/generate.bash
source ./home/.local/lib/bash/array.bash

{
    rc-new-workfile "$RC_DEP_INIT"

    rc-workfile-append-line '# shellcheck enable=deprecate-which'
    rc-workfile-append-line '# shellcheck disable=SC1090'
    rc-workfile-append-line '# shellcheck disable=SC1091'
    rc-workfile-append-line '# shellcheck disable=SC2059'

    if have local-bash && get-location bash; then
        rc-workfile-var __RC_BASH "${FACT:?}"
        rc-workfile-include ./bash/ssh-shell-check.bash
    fi

    if have-builtin timer && get-builtin-location timer; then
        rc-workfile-add-exec enable -f "${FACT:?}" timer
        rc-workfile-include ./bash/rc-timer-new.bash
    else
        rc-workfile-include ./bash/rc-timer-old.bash
    fi

    rc-workfile-include ./bash/rc-preamble.bash

    rc-workfile-close
}

{
    rc-new-workfile "$RC_DEP_TIMER"
    rc-workfile-add-dep "$RC_DEP_INIT"
    rc-workfile-close
}

{
    rc-new-workfile "$RC_DEP_ENV"
    rc-workfile-add-dep "$RC_DEP_INIT"
    rc-workfile-add-dep "$RC_DEP_TIMER"
    rc-workfile-add-exec source "${HOME:?}/.config/env"
    rc-workfile-close
}

{
    rc-new-workfile "$RC_DEP_DEBUG"
    rc-workfile-add-dep "$RC_DEP_ENV"
    rc-workfile-include ./bash/rc-debug.bash
    rc-workfile-close
}

{
    rc-new-workfile "$RC_DEP_BUILTINS"
    rc-workfile-add-dep "$RC_DEP_ENV"

    if have-builtin stat; then
        get-builtin-location stat
        rc-workfile-add-exec enable -f "${FACT:?}" stat

        # disable stat immediately so that callers expecting the
        # stat binary don't get confused
        rc-workfile-add-exec enable -n stat
    fi

    if have-builtin varsplice; then
        get-builtin-location varsplice
        rc-workfile-add-exec enable -f "${FACT:?}" varsplice
    fi

    rc-workfile-close
}

{
    rc-new-workfile "$RC_DEP_PATHSET"
    rc-workfile-add-dep "$RC_DEP_DEBUG"
    rc-workfile-add-dep "$RC_DEP_TIMER"
    rc-workfile-add-dep "$RC_DEP_BUILTINS"

    if have-builtin varsplice; then
        delim_vars=(
            PATH=':'
            MANPATH=':'
            CDPATH=':'
            LUA_PATH=';'
            LUA_CPATH=';'
            EXECIGNORE=':'
            FIGNORE=':'
            GLOBIGNORE=':'
            HISTIGNORE=':'
            XDG_DATA_DIRS=':'
            XDG_CONFIG_DIRS=':'
        )

        rc-workfile-timer-start "configure-delimited-vars"
        for elem in "${delim_vars[@]}"; do
            var=${elem%%=*}
            delim=${elem##*=}
            rc-workfile-add-exec builtin varsplice --default -s "${var:?}" "${delim:?}"
        done
        rc-workfile-timer-stop

        norm_vars=(
            PATH
            MANPATH
            CDPATH
            LUA_PATH
            LUA_CPATH
        )

        array-join-var default_path ':' \
            "$HOME/.local/bin" \
            /usr/local/bin \
            /usr/local/sbin \
            /usr/bin \
            /usr/sbin \

        rc-workfile-append-line 'if (( __RC_LOGIN_SHELL == 1 )); then'
        rc-workfile-append 'export PATH=%q\n' "${default_path:?}"
        rc-workfile-append-line 'fi'

        rc-workfile-timer-start "normalize-path-vars"
        for var in "${norm_vars[@]}"; do
            rc-workfile-add-exec builtin varsplice --normalize "$var"
        done
        rc-workfile-timer-stop

    else
        rc-workfile-include ./bash/rc-compat-pathset.bash
    fi

    rc-workfile-close
}
