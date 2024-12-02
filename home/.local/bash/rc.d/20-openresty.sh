found=0
for loc in ~/.local /usr/local; do
    resty_bin=$loc/openresty/bin
    nginx_bin=$loc/openresty/nginx/sbin

    if (( found == 0 )) && [[ -d $resty_bin && -d $nginx_bin ]]; then
        found=1
        __rc_add_path "$resty_bin" PATH
        __rc_add_path "$nginx_bin" PATH
    else
        __rc_rm_path "$resty_bin" PATH
        __rc_rm_path "$nginx_bin" PATH
    fi
done
unset loc found resty_bin nginx_bin || true
