# General shell options

# globbing should get files/directories that start with .
shopt -s dotglob

shopt -u failglob

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# I hate this thing
unset -f command_not_found_handle || true

# max open file descriptors
builtin ulimit -n $(( 1024 * 16 ))

# max processes
builtin ulimit -u $(( 1024 * 8 ))

if [[ -z ${COLORTERM:-} ]]; then
    case $TERM in
        alacritty) COLORTERM=truecolor;;
        xterm-kitty) COLORTERM=truecolor;;
    esac
fi
export COLORTERM
export TERM=${TERM:-tmux-256color}
