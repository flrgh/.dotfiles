# Make ssh agent forwarding work with persistent tmux/screen sessions

keyring=/run/user/${UID:?}/keyring/.ssh
auth_sock=$HOME/.ssh/ssh_auth_sock

if [[ -S $keyring ]]; then
    need_link=1
    if links-to "$auth_sock" "$keyring"; then
        need_link=0
    elif [[ -e $auth_sock ]]; then
        rm "$auth_sock"
    fi

    if (( need_link == 1 )); then
        __rc_debug "updating SSH_AUTH_SOCK symlink to keyring"
        ln -sf "$keyring" "$auth_sock"
    else
        __rc_debug "SSH_AUTH_SOCK is symlinked to the keyring"
    fi

    unset need_link

elif [[ -n $SSH_AUTH_SOCK && $SSH_AUTH_SOCK != "$auth_sock" ]]; then
    __rc_debug "symlink ssh auth sock to $SSH_AUTH_SOCK"
    ln -sf "$SSH_AUTH_SOCK" "$auth_sock"
fi

export SSH_AUTH_SOCK=${auth_sock}

unset keyring auth_sock
