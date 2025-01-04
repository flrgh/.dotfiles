#!/usr/bin/env bash

update_terminal() {
    local -r path=org.gnome.desktop.default-applications.terminal

    if command -v alacritty &>/dev/null; then
        echo "setting alacritty as the default terminal in gsettings"

        gsettings set "$path" exec     alacritty
        gsettings set "$path" exec-arg ""
    else
        echo "resetting $path to its default"

        gsettings reset "$path" exec
        gsettings reset "$path" exec-arg
    fi
}

main() {
    if ! command -v gsettings &>/dev/null; then
        echo "no gsettings found, exiting"
        return 0
    fi

    update_terminal
}

main
