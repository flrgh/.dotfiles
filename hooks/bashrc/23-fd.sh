#!/usr/bin/env bash

source ./lib/bash/generate.bash

# I have `find /some/path` permanently stored in muscle memory. This is an
# issue as I try using fd as a replacement, because the same invocation yields
# a "you're doing it wrong!" error:
#
#
# > [fd error]: The search pattern './' contains a path-separation character ('/') and will not lead to any search results.
# >
# > If you want to search for all files inside the './' directory, use a match-all pattern:
# >
# >  fd . './'
# >
# > If nstead, if you want your pattern to match the full file path, use:
# >
# >  fd --full-path './'
#
#
# This little function exists to handle that case so that I don't have to
# relearn anything
#
if command -v fd; then
    fd() {
        if (( $# == 1 )) && [[ $1 != . ]]; then
            command fd . "$1"
        else
            command fd "$@"
        fi
    }
    rc-new-workfile fd
    rc-workfile-add-dep "$RC_DEP_POST_INIT"
    rc-workfile-add-function fd
    rc-workfile-close
fi
