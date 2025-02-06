#!/usr/bin/env bash

source ./lib/bash/generate.bash
source ./lib/bash/facts.bash

rc-new-workfile "$RC_DEP_POST_INIT"
rc-workfile-add-dep "$RC_DEP_TIMER"

{
    rc-new-workfile "$RC_DEP_RESET_VAR"
    rc-workfile-add-dep "$RC_DEP_ENV"

    rc-new-workfile "$RC_DEP_SET_VAR"
    rc-workfile-add-dep "$RC_DEP_RESET_VAR"

    rc-new-workfile "$RC_DEP_CLEAR_VAR"
    rc-workfile-add-dep "$RC_DEP_ENV"
    rc-workfile-add-dep "$RC_DEP_SET_VAR"
}

{
    rc-new-workfile "$RC_DEP_ALIAS_RESET"
    rc-workfile-add-dep "$RC_DEP_ENV"
    rc-workfile-append 'unalias -a\n'

    rc-new-workfile "$RC_DEP_ALIAS_SET"
    rc-workfile-add-dep "$RC_DEP_ALIAS_RESET"
}

{
    rc-new-workfile "$RC_DEP_RESET_FUNCTION"
    rc-workfile-add-dep "$RC_DEP_ENV"

    rc-new-workfile "$RC_DEP_SET_FUNCTION"
    rc-workfile-add-dep "$RC_DEP_RESET_FUNCTION"

    rc-new-workfile "$RC_DEP_CLEAR_FUNCTION"
    rc-workfile-add-dep "$RC_DEP_SET_FUNCTION"
}

rc-new-workfile "$RC_DEP_ENV_POST"
rc-workfile-add-dep "$RC_DEP_CLEAR_VAR"
rc-workfile-add-dep "$RC_DEP_ALIAS_SET"
