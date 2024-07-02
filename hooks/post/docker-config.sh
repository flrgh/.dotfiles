#!/usr/bin/env bash

set -euo pipefail

source home/.local/bash/rc.d/20-app-docker.sh

mkdir -p "$DOCKER_CONFIG"

readonly CONFIG_FILE=${DOCKER_CONFIG}/config.json

if [[ ! -e "$CONFIG_FILE" ]]; then
    echo "Creating docker config file ($CONFIG_FILE)"
    jq --null-input '{}' > "$CONFIG_FILE"
fi

declare -g CONFIG
CONFIG=$(jq < "$CONFIG_FILE")

edit-config() {
    local result
    result=$(jq <<< "$CONFIG" "$@")
    CONFIG="$result"
}

edit-config '.auths //= {} | .auths["https://index.docker.io/v1/"] //= {}'
edit-config '.experimental = "enabled"'
edit-config '.psFormat = "table {{.Names}}\t{{.Image}}\t{{.Networks}}\t{{.Status}}\t{{.Command}}"'

if command -v docker-credential-secretservice &>/dev/null \
    && docker-credential-secretservice list &>/dev/null
then
    echo "Enabling secretservice credential provider"
    edit-config '.credsStore = "secretservice"'
else
    echo "Disabling secretservice credential provider"
    edit-config 'if .credsStore == "secretservice" then del(.credsStore) else . end'
fi


diff <(jq -S . <   "$CONFIG_FILE") \
     <(jq -S . <<< "$CONFIG") \
|| true

echo "Updating config file"
CONFIG=$(jq -S <<< "$CONFIG")
printf '%s\n' "$CONFIG" > "$CONFIG_FILE"
