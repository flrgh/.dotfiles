# these are mostly used by my own scripts
export CONFIG_HOME=$HOME/.config
export CACHE_DIR=$HOME/.cache

# XDG
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
export XDG_CONFIG_HOME=$CONFIG_HOME
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$CACHE_DIR
# this is probably os-specific
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$UID}


# lang/charset
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# clean slate
unset PROMPT_COMMAND
