for loc in ~/.local/openresty/current ~/.local/openresty /usr/local/openresty; do
    resty_bin=$loc/bin
    nginx_bin=$loc/nginx/sbin
    __rc_rm_path PATH "$resty_bin"
    __rc_rm_path PATH "$nginx_bin"
done
unset loc resty_bin nginx_bin || true
