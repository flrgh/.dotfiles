# Make ssh agent forwarding work with persistent tmux/screen sessions
if [[ -S "$SSH_AUTH_SOCK" && ! -h "$SSH_AUTH_SOCK" ]]; then
    _debug_rc "ln -sf \"$SSH_AUTH_SOCK\" ~/.ssh/ssh_auth_sock"
    ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
fi
export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
