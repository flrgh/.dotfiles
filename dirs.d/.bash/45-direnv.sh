# direnv hook
#
# @see https://direnv.net/docs/installation.html

if iHave direnv; then
    eval "$(direnv hook bash)"
fi
