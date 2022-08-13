if [[ -d /usr/local/openresty/bin ]]; then
    addPath /usr/local/openresty/bin

    if [[ -d /usr/local/openresty/nginx/sbin ]]; then
        addPath /usr/local/openresty/nginx/sbin
    fi
fi
