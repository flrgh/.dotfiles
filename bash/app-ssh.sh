# Make ssh agent forwarding work with persistent tmux/screen sessions

dir=${XDG_RUNTIME_DIR:-/run/user/${UID:-$(id -u)}}/keyring
for sock in "${dir}/ssh" "${dir}/.ssh"; do
    if [[ -e $sock ]]; then
        export SSH_AUTH_SOCK=$sock
        break
    fi
done
unset dir sock
