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
    rc-new-workfile "$RC_DEP_DEBUG"
    rc-workfile-add-dep "$RC_DEP_INIT"
    rc-workfile-include ./bash/rc-debug.bash
    rc-workfile-close
}

{
    rc-new-workfile "$RC_DEP_TIMER"
    rc-workfile-add-dep "$RC_DEP_DEBUG"

    rc-workfile-append '%s\n' 'if (( DEBUG_BASHRC > 0 )); then'

    if have timer && get-location timer; then
        rc-workfile-add-exec enable -f "${FACT:?}" timer
        rc-workfile-include ./bash/rc-timer-new.bash
    else
        rc-workfile-include ./bash/rc-timer-old.bash
    fi

    rc-workfile-append '%s\n' 'fi'

    rc-workfile-close
}
