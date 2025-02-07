#!/usr/bin/env bash

set -euo pipefail

source ./lib/bash/generate.bash
source ./lib/bash/facts.bash

{
    rc-new-workfile "$RC_DEP_INIT"
    rc-workfile-include ./bash/rc-preamble.bash
    rc-workfile-close
}

{
    rc-new-workfile "$RC_DEP_ENV"
    rc-workfile-add-dep "$RC_DEP_INIT"
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
}

{
    rc-new-workfile "$RC_DEP_TIMER"
    rc-workfile-add-dep "$RC_DEP_ENV"
    rc-workfile-add-dep "$RC_DEP_DEBUG"
    rc-workfile-add-dep "$RC_DEP_BUILTINS"

    rc-workfile-append '%s\n' 'if (( DEBUG_BASHRC > 0 )); then'

    if have-builtin timer && get-builtin-location timer; then
        rc-workfile-add-exec enable -f "${FACT:?}" timer
        rc-workfile-include ./bash/rc-timer-new.bash
    else
        rc-workfile-include ./bash/rc-timer-old.bash
    fi

    rc-workfile-append '%s\n' 'fi'

    rc-workfile-close
}
