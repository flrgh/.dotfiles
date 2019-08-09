#!/usr/bin/env bash

if ! command -v systemctl > /dev/null; then
    echo must not be a systemd system
    exit 0
fi

systemctl --user daemon-reload
