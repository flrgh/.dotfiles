# Make ssh agent forwarding work with persistent tmux/screen sessions,
# using gnome-keyring (workstation) and ssh-agent-switcher (server)

__keyring_dir=${XDG_RUNTIME_DIR:-/run/user/${UID:-$(id -u)}}/keyring
__switcher_sock=/tmp/ssh-agent.${USER:-$(id -un)}

if [[ -S ${__keyring_dir}/ssh ]]; then
    export SSH_AUTH_SOCK=${__keyring_dir}/ssh
elif [[ -S ${__keyring_dir}/.ssh ]]; then
    export SSH_AUTH_SOCK=${__keyring_dir}/.ssh
else
    if [[ ! -S $__switcher_sock ]] \
        && command -v ssh-agent-switcher >/dev/null 2>&1; then
        ssh-agent-switcher --daemon 2>/dev/null || true
    fi
    if [[ -S $__switcher_sock ]]; then
        export SSH_AUTH_SOCK=$__switcher_sock
    fi
fi

unset __keyring_dir __switcher_sock
