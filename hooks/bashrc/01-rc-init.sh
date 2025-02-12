#!/usr/bin/env bash

set -euo pipefail

source ./lib/bash/generate.bash
source ./lib/bash/facts.bash

{
    rc-new-workfile "$RC_DEP_INIT"

    rc-workfile-append-line '# shellcheck enable=deprecate-which'
    rc-workfile-append-line '# shellcheck disable=SC1090'
    rc-workfile-append-line '# shellcheck disable=SC1091'
    rc-workfile-append-line '# shellcheck disable=SC2059'

    if have local-bash; then
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
        rc-workfile-timer-start "configure-delimited-vars"
        rc-workfile-add-exec builtin varsplice --default -s PATH       ":"
        rc-workfile-add-exec builtin varsplice --default -s MANPATH    ":"
        rc-workfile-add-exec builtin varsplice --default -s CDPATH     ":"
        rc-workfile-add-exec builtin varsplice --default -s LUA_PATH   ";"
        rc-workfile-add-exec builtin varsplice --default -s LUA_CPATH  ";"
        rc-workfile-add-exec builtin varsplice --default -s EXECIGNORE ":"
        rc-workfile-add-exec builtin varsplice --default -s FIGNORE    ":"
        rc-workfile-add-exec builtin varsplice --default -s GLOBIGNORE ":"
        rc-workfile-add-exec builtin varsplice --default -s HISTIGNORE ":"
        rc-workfile-timer-stop

        rc-workfile-timer-start "normalize-path-vars"
        rc-workfile-add-exec builtin varsplice --normalize PATH
        rc-workfile-add-exec builtin varsplice --normalize MANPATH
        rc-workfile-add-exec builtin varsplice --normalize CDPATH
        rc-workfile-add-exec builtin varsplice --normalize LUA_PATH
        rc-workfile-add-exec builtin varsplice --normalize LUA_CPATH
        rc-workfile-timer-stop
    else
        rc-workfile-include ./bash/rc-compat-pathset.bash
    fi

    rc-workfile-close
}
