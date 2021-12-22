if [[ $XDG_SESSION_TYPE == wayland ]] && comand -v firefox-wayland &>/dev/null; then
    export MOZ_DBUS_REMOTE=1
    export GDK_BACKEND=wayland
    export MOZ_ENABLE_WAYLAND=1
fi
