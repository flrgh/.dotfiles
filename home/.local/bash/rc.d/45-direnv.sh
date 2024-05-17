# direnv hook
#
# @see https://direnv.net/docs/installation.html

if __rc_command_exists direnv; then
    eval "$(direnv hook bash)"
fi
