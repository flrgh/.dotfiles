# Make ssh agent forwarding work with persistent tmux/screen sessions
if test -S "/run/user/$UID/keyring/.ssh"; then
    ln -sf "/run/user/$UID/keyring/.ssh" ~/.ssh/ssh_auth_sock
    export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock

elif [[ -S "$SSH_AUTH_SOCK" && ! -h "$SSH_AUTH_SOCK" ]]; then
    __rc_debug "ln -sf \"$SSH_AUTH_SOCK\" ~/.ssh/ssh_auth_sock"
    ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
fi
export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
