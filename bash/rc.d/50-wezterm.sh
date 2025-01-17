if [[ -n ${WEZTERM_EXECUTABLE:-} && -n ${WEZTERM_PANE:-} ]]; then
    __rc_debug "wezterm detected"
else
    __rc_debug "disabling wezterm support"
    export WEZTERM_SHELL_SKIP_ALL=1
fi
