# Make ssh agent forwarding work with persistent tmux/screen sessions,
# using gcr-ssh-agent / gnome-keyring (workstation) and ssh-agent-switcher (server)

__runtime_dir=${XDG_RUNTIME_DIR:-/run/user/${UID:-$(id -u)}}
__gcr_sock=${__runtime_dir}/gcr/ssh
__keyring_dir=${__runtime_dir}/keyring
__switcher_sock=${__runtime_dir}/ssh-agent.sock

if [[ -S $__gcr_sock ]]; then
    export SSH_AUTH_SOCK=$__gcr_sock
elif [[ -S ${__keyring_dir}/ssh ]]; then
    export SSH_AUTH_SOCK=${__keyring_dir}/ssh
elif [[ -S ${__keyring_dir}/.ssh ]]; then
    export SSH_AUTH_SOCK=${__keyring_dir}/.ssh
elif [[ -S $__switcher_sock ]]; then
    export SSH_AUTH_SOCK=$__switcher_sock
fi

unset __runtime_dir __gcr_sock __keyring_dir __switcher_sock
