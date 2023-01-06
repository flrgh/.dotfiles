if [[ -n ${WEZTERM_EXECUTABLE:-} && -n ${WEZTERM_PANE:-} ]]; then
    _debug_rc "wezterm detected"
else
    _debug_rc "disabling wezterm support"
    export WEZTERM_SHELL_SKIP_ALL=1
fi
