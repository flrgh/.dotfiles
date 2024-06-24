# shellcheck source=home/.config/env
source "$HOME"/.config/env

export MY_BASH_STDLIB=$HOME/.local/lib/bash/std.bash
if [[ ! -f "$MY_BASH_STDLIB" ]]; then
    __rc_log "WARN: \$MY_BASH_STDLIB ($MY_BASH_STDLIB) file not found"
fi
