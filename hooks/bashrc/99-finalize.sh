#!/usr/bin/env bash

source ./lib/bash/generate.bash

set -euo pipefail

rc-new-workfile "rc-timer-post"
rc-new-workfile "rc-cleanup"
rc-workfile-add-dep "rc-timer-post"

get-list-items "$_ALL_FILES"

declare -a ALL=("${FACT_LIST[@]}")
for item in "${ALL[@]}"; do
    if [[ $item = rc-* ]]; then
        continue
    fi
    rc-workfile-add-dep "$item"
done

rc-workfile-include ./bash/rc-cleanup.bash
rc-workfile-close

rc-finalize
