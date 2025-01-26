#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR

set -euo pipefail

source "$INEED_ROOT/lib.sh"

main() {
    local fn=$1
    local -r name=$2
    local -r driver="$INEED_DRIVERS/${name}.sh"

    if [[ ! -x "$driver" ]]; then
        printf 'FATAL: driver for %s (%q) does not exist or is not executable\n' \
            "$name" \
            "$driver" \
        >&2

        exit 127
    fi

    shift 2

    # shellcheck source-path=SCRIPTDIR
    source "$INEED_ROOT/base-driver.sh"

    # shellcheck disable=SC1090
    source "$driver"

    if ! function-exists "$fn"; then
        fn="base-driver::${fn}"
    fi

    if ! function-exists "$fn"; then
        printf 'FATAL: function "%s" is not implemented by "%s" driver\n' \
            "${fn#base-driver::}" \
            "$name" \
        >&2

        exit 127
    fi

    "$fn" "$@"
}

main "$@"
