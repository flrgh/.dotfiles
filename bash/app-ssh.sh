# Make ssh agent forwarding work with persistent tmux/screen sessions,
# using gnome-keyring (workstation) and ssh-agent-switcher (server)

__keyring_dir=${XDG_RUNTIME_DIR:-/run/user/${UID:-$(id -u)}}/keyring
__switcher_sock=${XDG_RUNTIME_DIR:-/run/user/${UID:-$(id -u)}}/ssh-agent.sock

if [[ -S ${__keyring_dir}/ssh ]]; then
    export SSH_AUTH_SOCK=${__keyring_dir}/ssh
elif [[ -S ${__keyring_dir}/.ssh ]]; then
    export SSH_AUTH_SOCK=${__keyring_dir}/.ssh
elif [[ -S $__switcher_sock ]]; then
    export SSH_AUTH_SOCK=$__switcher_sock
fi

unset __keyring_dir __switcher_sock
