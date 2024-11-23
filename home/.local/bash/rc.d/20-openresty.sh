for loc in ~/.local /usr/local; do
    if [[ -d $loc/openresty/bin && -d $loc/openresty/nginx/sbin ]]; then
        __rc_add_path "$loc"/openresty/nginx/sbin
        __rc_add_path "$loc"/openresty/bin

        break
    fi
done
unset loc || true
