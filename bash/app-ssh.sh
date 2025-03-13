# Make ssh agent forwarding work with persistent tmux/screen sessions

sock=${XDG_RUNTIME_DIR:-/run/user/${UID:-$(id -u)}}/keyring/.ssh
if [[ ${SSH_AUTH_SOCK:-} != "$sock" ]]; then
    export SSH_AUTH_SOCK=$sock
fi
unset sock
