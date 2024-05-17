if [[ -d /usr/local/openresty/bin ]]; then
    __rc_add_path /usr/local/openresty/bin

    if [[ -d /usr/local/openresty/nginx/sbin ]]; then
        __rc_add_path /usr/local/openresty/nginx/sbin
    fi
fi
