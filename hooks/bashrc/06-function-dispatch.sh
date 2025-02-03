#!/usr/bin/env bash

source ./lib/bash/generate.bash
source ./home/.local/lib/bash/dispatch.bash

rc-new-workfile "function-dispatch"
rc-workfile-add-dep "$RC_DEP_SET_VAR"
rc-workfile-add-function __function_dispatch
