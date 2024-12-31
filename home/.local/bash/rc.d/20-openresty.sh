found=0
for loc in ~/.local/openresty/current ~/.local/openresty /usr/local/openresty; do
    resty_bin=$loc/bin
    nginx_bin=$loc/nginx/sbin

    if (( found == 0 )) && [[ -d $resty_bin && -d $nginx_bin ]]; then
        found=1
        __rc_add_path PATH "$resty_bin"
        __rc_add_path PATH "$nginx_bin"
    else
        __rc_rm_path PATH "$resty_bin"
        __rc_rm_path PATH "$nginx_bin"
    fi
done
unset loc found resty_bin nginx_bin || true
