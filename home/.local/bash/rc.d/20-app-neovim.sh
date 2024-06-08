if __rc_command_exists nvim &>/dev/null; then
    __rc_debug "neovim is installed; aliasing vim=nvim"
    alias vim=nvim
    export EDITOR=nvim
fi
